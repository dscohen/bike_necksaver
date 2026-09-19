// periscope.scad
//
// Parametric bike periscope housing.
//
// Background / derivation: see docs/design-notes.md. Short version:
//   - mirror_count = 1: single 45deg-ish mirror test rig. Inverts the
//     vertical image (near road at top, horizon at bottom) -- it exists to
//     find out whether that's adaptable, and to measure your real head
//     pitch (theta) before committing to the two-mirror build.
//   - mirror_count = 2: corrects the inversion. Net deviation = 2 * dihedral,
//     so dihedral = theta / 2. Incidence angles i1, i2 satisfy
//     i1 - i2 = theta / 2, and each mirror's clear length = aperture / cos(i).
//
// Mirrors are NOT custom-cut: the housing accepts a standard off-the-shelf
// 160mm x 100mm (6.3" x 3.94") acrylic mirror tile, sliding into a captured
// 3-sided channel so it can be dropped in / swapped without glue.
//
// Mounts to a stem faceplate via slotted (not round) bolt holes, so the
// same bracket tolerates faceplate-to-faceplate variation in bolt spacing.

/* [Optics] */
mirror_count   = 1;     // [1, 2] -- 1 = test rig, 2 = inversion-corrected
theta          = 60;    // deg, head pitch below horizontal
eye_to_device  = 500;   // mm, eye to front mirror
target_aperture = 75;   // mm, desired optical aperture (clamped to mirror stock)
max_incidence  = 55;    // deg, cap per mirror before foreshortening blows up the size

/* [Mirror stock -- off-the-shelf acrylic mirror tile] */
mirror_stock_length = 160;  // mm (6.3")
mirror_stock_width  = 100;  // mm (3.94")
mirror_thickness    = 3;    // mm -- CONFIRM against the actual product; 3mm assumed
mirror_clearance     = 0.4; // mm, per-side slide clearance in the channel
channel_lip          = 4;   // mm, captured lip width on the 3 closed sides
retainer_lip         = 3;   // mm, height of the printed retaining clip on the open edge

/* [Stem faceplate mount] */
faceplate_bolt_dia      = 5.5;  // mm, clearance for M5 faceplate bolts (common; M4 also seen)
faceplate_spacing_x     = 40;   // mm, nominal horizontal bolt spacing
faceplate_spacing_y     = 32;   // mm, nominal vertical bolt spacing
slot_play               = 6;    // mm, extra travel per slot to cover stem-to-stem variance
mount_plate_thickness   = 6;    // mm

/* [Test-rig tilt adjustment (mirror_count = 1 only)] */
tilt_range = 10; // deg, +/- adjustment range on the test-rig mount

/* [Rendering] */
$fn = 48;

// ---------------------------------------------------------------------
// Derived optics -- printed to the console so you can iterate on paper
// before printing. Ideal numbers come straight from the conversation's
// math; achievable numbers clamp to what the fixed mirror stock allows.
// ---------------------------------------------------------------------

usable_mirror_length = mirror_stock_length - 2 * channel_lip;

function mirror_len_for(aperture, incidence) = aperture / cos(incidence);

// Single-mirror case: one 45-ish fold, deviation = theta, so incidence = theta/2.
i_single = theta / 2;
ideal_len_single = mirror_len_for(target_aperture, i_single);
achievable_aperture_single = min(target_aperture, usable_mirror_length * cos(i_single));

// Two-mirror case: dihedral = theta/2, and i1 - i2 = dihedral. Take i1 as
// large as allowed (maximizes both mirrors' usable length) and derive i2.
dihedral = theta / 2;
i1_two = max_incidence;
i2_two = max(0, i1_two - dihedral);

ideal_len_m1 = mirror_len_for(target_aperture, i1_two);
ideal_len_m2 = mirror_len_for(target_aperture, i2_two);
achievable_aperture_two = min(target_aperture,
                               usable_mirror_length * cos(i1_two),
                               usable_mirror_length * cos(i2_two));

fov_ideal = target_aperture / eye_to_device;
fov_achievable_single = achievable_aperture_single / eye_to_device;
fov_achievable_two = achievable_aperture_two / eye_to_device;

echo("---- Bike periscope: derived optics ----");
echo(str("theta (head pitch): ", theta, " deg"));
echo(str("mirror stock: ", mirror_stock_length, "x", mirror_stock_width, "x", mirror_thickness, " mm, usable length ", usable_mirror_length, " mm"));

if (mirror_count == 1) {
    echo(str("single mirror incidence: ", i_single, " deg"));
    echo(str("ideal mirror length for target aperture: ", ideal_len_single, " mm"));
    echo(str("achievable aperture on stock mirror: ", achievable_aperture_single, " mm (target was ", target_aperture, " mm)"));
    echo(str("FOV ideal / achievable: ", fov_ideal * 180 / PI, " / ", fov_achievable_single * 180 / PI, " deg (small-angle approx)"));
    if (ideal_len_single > usable_mirror_length)
        echo("WARNING: target aperture needs a longer mirror than the 160mm stock provides at this theta -- aperture has been clamped.");
} else {
    echo(str("dihedral: ", dihedral, " deg, i1: ", i1_two, " deg, i2: ", i2_two, " deg"));
    echo(str("ideal mirror lengths -- M1: ", ideal_len_m1, " mm, M2: ", ideal_len_m2, " mm"));
    echo(str("achievable aperture on stock mirrors: ", achievable_aperture_two, " mm (target was ", target_aperture, " mm)"));
    echo(str("FOV ideal / achievable: ", fov_ideal * 180 / PI, " / ", fov_achievable_two * 180 / PI, " deg (small-angle approx)"));
    if (max(ideal_len_m1, ideal_len_m2) > usable_mirror_length)
        echo("WARNING: ideal mirror length exceeds the 160mm stock at this theta -- aperture has been clamped, consider reducing theta or target_aperture.");
}

// ---------------------------------------------------------------------
// Mirror channel: 3-sided captured slot sized to the stock mirror, open
// on one edge for sliding the mirror in. Cut as a hole from the caller's
// frame solid -- see mirror_seat().
// ---------------------------------------------------------------------

module mirror_channel(open_edge = "top") {
    // Pocket sized to the mirror + clearance; the surrounding frame
    // material (passed in by the caller) forms the lip on the 3 closed
    // sides. This module only cuts the pocket and the open slide-in throat.
    l = mirror_stock_length + 2 * mirror_clearance;
    w = mirror_stock_width + 2 * mirror_clearance;
    t = mirror_thickness + 2 * mirror_clearance;

    translate([-l/2, -w/2, -t/2])
        cube([l, w, t]);

    // Throat: extends the pocket through the frame on the open edge so
    // the mirror can slide in from outside.
    throat_len = channel_lip + 5;
    if (open_edge == "top")
        translate([-l/2, w/2 - 0.01, -t/2]) cube([l, throat_len, t]);
    else if (open_edge == "bottom")
        translate([-l/2, -w/2 - throat_len + 0.01, -t/2]) cube([l, throat_len, t]);
    else if (open_edge == "left")
        translate([-l/2 - throat_len + 0.01, -w/2, -t/2]) cube([throat_len, w, t]);
    else
        translate([l/2 - 0.01, -w/2, -t/2]) cube([throat_len, w, t]);
}

// Retaining clip that closes the open edge after the mirror is inserted.
module retainer_clip(open_edge = "top") {
    l = mirror_stock_length + 2 * mirror_clearance + 2 * channel_lip;
    clip_w = channel_lip + 1;
    if (open_edge == "top" || open_edge == "bottom")
        cube([l, clip_w, retainer_lip], center = true);
    else
        cube([clip_w, l, retainer_lip], center = true);
}

// One mirror "seat": a flat plate sized to the mirror + lip on all sides,
// with the mirror channel cut into it. Frame thickness = mirror_thickness
// + 2*mirror_clearance + a bit of backing material behind the mirror.
module mirror_seat(open_edge = "top") {
    backing = 2.5; // mm of solid material behind the mirror for stiffness
    frame_l = mirror_stock_length + 2 * mirror_clearance + 2 * channel_lip;
    frame_w = mirror_stock_width + 2 * mirror_clearance + 2 * channel_lip;
    frame_t = mirror_thickness + 2 * mirror_clearance + backing;

    difference() {
        cube([frame_l, frame_w, frame_t], center = true);
        translate([0, 0, backing/2])
            mirror_channel(open_edge = open_edge);
    }
}

// ---------------------------------------------------------------------
// Stem faceplate mount: slotted holes instead of fixed round holes so
// the same bracket tolerates variation in faceplate bolt spacing.
// ---------------------------------------------------------------------

module mount_slot() {
    // Horizontal slot: play in X, matches vertical spacing exactly (Y
    // varies less between stems than X in practice).
    hull() {
        translate([-slot_play/2, 0, 0]) circle(d = faceplate_bolt_dia);
        translate([slot_play/2, 0, 0]) circle(d = faceplate_bolt_dia);
    }
}

module faceplate_mount() {
    plate_l = faceplate_spacing_x + slot_play + 2 * faceplate_bolt_dia * 1.5;
    plate_w = faceplate_spacing_y + 2 * faceplate_bolt_dia * 1.5;

    difference() {
        cube([plate_l, plate_w, mount_plate_thickness], center = true);
        for (x = [-faceplate_spacing_x/2, faceplate_spacing_x/2])
            for (y = [-faceplate_spacing_y/2, faceplate_spacing_y/2])
                translate([x, y, 0])
                    linear_extrude(height = mount_plate_thickness + 2, center = true)
                        mount_slot();
    }
}

// ---------------------------------------------------------------------
// Assemblies
// ---------------------------------------------------------------------

module test_rig() {
    // Single mirror on a tilt-adjustable riser above the faceplate mount.
    // tilt_range is realized as a printed protractor/notch set in the
    // riser (left as a manual-adjust detail -- see docs/design-notes.md
    // for the fitting procedure); geometry here shows the nominal
    // incidence angle i_single.
    faceplate_mount();

    riser_h = 60;
    translate([0, 0, mount_plate_thickness/2 + riser_h/2])
        cube([20, 20, riser_h], center = true);

    translate([0, 0, mount_plate_thickness + riser_h])
        rotate([90 - i_single, 0, 0])
            mirror_seat(open_edge = "top");
}

module two_mirror_rig() {
    // Both mirror seats are unioned from ONE shared datum/orientation
    // (this module) rather than assembled from separately-printed,
    // separately-oriented parts -- that's what keeps the two hinge axes
    // parallel to within the ~0.5deg the design notes call for. Only
    // M2's pitch is meant to be field-adjustable; M1 is fixed here.
    faceplate_mount();

    stack_gap = ideal_len_m1 * 0.6; // approx spacing between mirrors

    translate([0, 0, mount_plate_thickness/2 + 10])
        rotate([90 - i1_two, 0, 0])
            mirror_seat(open_edge = "top");

    translate([0, 0, mount_plate_thickness/2 + 10 + stack_gap])
        rotate([90 - i2_two, 0, 0])
            mirror_seat(open_edge = "bottom");
}

if (mirror_count == 1)
    test_rig();
else
    two_mirror_rig();
