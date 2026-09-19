// periscope.scad
//
// Parametric bike periscope housing.
//
// Background / derivation: see docs/design-notes.md. Short version:
//   - mirror_count = 1: single mirror test rig. Bends the sightline by
//     theta correctly, but a single reflection INVERTS the vertical image
//     (near road at top, horizon at bottom). It exists to find out whether
//     that's adaptable, and to measure your real head pitch before
//     committing to the two-mirror build.
//   - mirror_count = 2: "normal vision" build. Two reflections = even
//     parity, so vertical orientation comes back correct.
//
// Geometry convention: X = forward (direction of travel), Y = left, Z = up,
// matching the bike when upright. Everything is derived by tracing the
// actual sightline rather than by assuming angles:
//
//   d_in   the rider's gaze, theta below horizontal, entering mirror 1
//   d_mid  the ray between the two mirrors (its elevation is the one real
//          shape knob -- see mid_elevation)
//   d_out  [1,0,0], horizontal, what the rider ends up seeing along
//
// A mirror turning ray d into ray d' has unit normal n = unit(d' - d), and
// its angle of incidence is acos(-d . n). NOTE these are different angles:
// a mirror whose normal tilts 30 degrees from vertical can easily be
// sitting at 60 degrees of incidence. Incidence is what sets foreshortening
// (clear aperture = mirror length * cos(incidence)), so it is what the
// aperture math below uses.
//
// Mirrors are NOT custom-cut: the housing accepts a standard off-the-shelf
// 160mm x 100mm (6.3" x 3.94") acrylic mirror tile, sliding into a captured
// channel so it drops in without glue and can be swapped.
//
// Mounts to a stem faceplate via slotted (not round) bolt holes, so the
// same bracket tolerates faceplate-to-faceplate variation in bolt spacing.

/* [Optics] */
mirror_count    = 1;    // [1, 2] -- 1 = test rig, 2 = inversion-corrected
theta           = 60;   // deg, head pitch below horizontal
eye_to_device   = 500;  // mm, eye to first mirror
target_aperture = 75;   // mm, desired optical aperture (clamped to mirror stock)

// Elevation (deg above horizontal) of the ray running between the two
// mirrors. This is the one real shape knob on the 2-mirror build: raising
// it lowers both angles of incidence, which buys aperture and field of
// view, at the cost of standing mirror 2 higher above mirror 1. 90 = a
// vertical mast with mirror 2 straight above mirror 1. Below about 40 the
// incidence at mirror 2 gets so grazing that the aperture collapses.
mid_elevation = 75;     // deg

grazing_warn = 65;      // deg, warn above this angle of incidence

// Which stock-mirror dimension lies along the fold (the direction that gets
// foreshortened by cos(incidence), and so sets the aperture). "length" uses
// the 160mm side -- more aperture, bigger device. "width" uses the 100mm
// side -- less aperture, a much more manageable object on a bike.
fold_axis = "length";   // ["length", "width"]

/* [Mirror stock -- off-the-shelf acrylic mirror tile] */
mirror_stock_length = 160;  // mm (6.3")
mirror_stock_width  = 100;  // mm (3.94")
mirror_thickness    = 3;    // mm -- CONFIRM against the actual product; 3mm assumed
mirror_clearance    = 0.4;  // mm, per-side slide clearance in the channel
channel_lip         = 4;    // mm, captured lip width around the mirror
mirror_backing      = 2.5;  // mm, solid material behind the mirror

/* [Frame] */
mirror_gap   = 0;    // mm between mirror centers along the folded path; 0 = auto
rail_dia     = 9;    // mm, support rail diameter (2-mirror build)
rail_inset   = 2.5;  // mm, how far rails bite into the seat's outer lip
riser_l      = 30;   // mm, riser post size along X
riser_w      = 26;   // mm, riser post size along Y
riser_height = 55;   // mm, mount face to first mirror center
joint_merge  = 1.5;  // mm, how far supports sink into a mirror's backing
corner_r     = 5;    // mm, cosmetic corner rounding

/* [Stem faceplate mount] */
faceplate_bolt_dia    = 5.5;  // mm, clearance for M5 faceplate bolts (M4 also seen)
faceplate_spacing_x   = 40;   // mm, nominal horizontal bolt spacing
faceplate_spacing_y   = 32;   // mm, nominal vertical bolt spacing
slot_play             = 6;    // mm, extra travel per slot for stem-to-stem variance
mount_plate_thickness = 6;    // mm

/* [Rendering] */
$fn = 48;

BIG = 2000; // scratch size for half-space clipping

// ---------------------------------------------------------------------
// Vector helpers
// ---------------------------------------------------------------------

function unit(v) = v / norm(v);

// Unit normal of the mirror that turns ray d into ray d2.
function mirror_normal(d, d2) = unit(d2 - d);

// Angle of incidence of ray d on a mirror with unit normal n.
function incidence(d, n) = acos(-d * n);

// Plate tilt for OpenSCAD's rotate([0, phi, 0]), which puts a flat plate's
// normal at [sin(phi), 0, cos(phi)].
function tilt_of(n) = atan2(n[0], n[2]);

// A point on a seat's mid-plane: seat centered at P, tilted phi, local
// offsets (x, y) within the plate.
function seat_pt(P, phi, x, y) = P + [x * cos(phi), y, -x * sin(phi)];

// ---------------------------------------------------------------------
// Ray path
// ---------------------------------------------------------------------

d_in  = [cos(theta), 0, -sin(theta)];
d_out = [1, 0, 0];
d_mid = [cos(mid_elevation), 0, sin(mid_elevation)];

// Single mirror: one fold straight from d_in to d_out.
n_single   = mirror_normal(d_in, d_out);
phi_single = tilt_of(n_single);
inc_single = incidence(d_in, n_single);

// Two mirrors: d_in -> d_mid at M1, d_mid -> d_out at M2.
n1   = mirror_normal(d_in, d_mid);
n2   = mirror_normal(d_mid, d_out);
phi1 = tilt_of(n1);
phi2 = tilt_of(n2);
inc1 = incidence(d_in, n1);
inc2 = incidence(d_mid, n2);

// ---------------------------------------------------------------------
// Derived sizes. Clear aperture is the mirror's usable length foreshortened
// by cos(incidence), capped at what the rider actually wants.
// ---------------------------------------------------------------------

fold_dim = (fold_axis == "length") ? mirror_stock_length : mirror_stock_width;
span_dim = (fold_axis == "length") ? mirror_stock_width  : mirror_stock_length;

usable_fold = fold_dim - 2 * channel_lip;

function aperture_from(inc) = usable_fold * cos(inc);

aperture_single = min(target_aperture, aperture_from(inc_single));
aperture_two    = min(target_aperture, aperture_from(inc1), aperture_from(inc2));

// Seat envelope
frame_fold = fold_dim + 2 * mirror_clearance + 2 * channel_lip;
frame_span = span_dim + 2 * mirror_clearance + 2 * channel_lip;
frame_t    = mirror_thickness + 2 * mirror_clearance + mirror_backing;

// Mirror separation along the folded path. Below roughly the seat's own
// fold dimension the two plates start to intersect, so auto leaves margin.
gap = (mirror_gap > 0) ? mirror_gap : frame_fold * 1.15;

P1 = [0, 0, mount_plate_thickness / 2 + riser_height];
P2 = P1 + gap * d_mid;

// ---------------------------------------------------------------------
// Console report -- iterate here before printing anything.
// ---------------------------------------------------------------------

echo("---- Bike periscope ----");
echo(str("head pitch: ", theta, " deg   mirror stock: ",
         mirror_stock_length, "x", mirror_stock_width, "x", mirror_thickness,
         " mm   fold axis: ", fold_axis, " (", usable_fold, " mm usable)"));

if (mirror_count == 1) {
    echo(str("mirror: normal tilted ", phi_single, " deg, incidence ", inc_single,
             " deg (foreshortening ", 1 / cos(inc_single), "x)"));
    echo(str("aperture: ", aperture_single, " mm of a possible ",
             aperture_from(inc_single), " mm   FOV: ",
             atan(aperture_single / eye_to_device), " deg"));
    echo("NOTE: one reflection -- the vertical image is INVERTED. Use mirror_count = 2 for correct orientation.");
    if (inc_single > grazing_warn)
        echo(str("WARNING: incidence ", inc_single, " deg is grazing; the mirror is mostly wasted."));
} else {
    echo(str("M1: normal tilt ", phi1, " deg, incidence ", inc1, " deg"));
    echo(str("M2: normal tilt ", phi2, " deg, incidence ", inc2, " deg"));
    echo(str("aperture: ", aperture_two, " mm   FOV: ",
             atan(aperture_two / eye_to_device), " deg"));
    echo(str("mirror separation ", gap, (mirror_gap > 0) ? " mm" : " mm (auto)",
             "  -> M2 sits ", P2[0] - P1[0], " mm forward and ",
             P2[2] - P1[2], " mm above M1"));
    echo(str("exit sightline ", d_out, "  vertical orientation: CORRECT (two reflections)"));
    if (max(inc1, inc2) > grazing_warn)
        echo(str("WARNING: incidence up to ", max(inc1, inc2),
                 " deg is grazing and collapses the aperture. Raise mid_elevation."));
    echo(str("overall height above the mount: ", P2[2] + frame_fold/2, " mm",
             " -- set fold_axis = \"width\" for a much smaller device."));
}

// ---------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------

module rrect(l, w, r) {
    hull()
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (l/2 - r), sy * (w/2 - r)])
                circle(r = r);
}

module rod(a, b, d) {
    taper_rod(a, b, d, d);
}

module taper_rod(a, b, da, db) {
    hull() {
        translate(a) sphere(d = da);
        translate(b) sphere(d = db);
    }
}

// ---------------------------------------------------------------------
// Mirror seat: rounded plate with a captured channel for the stock mirror,
// open on one fold-axis edge so the mirror slides in.
// ---------------------------------------------------------------------

module seat_pocket(open_edge) {
    l = fold_dim + 2 * mirror_clearance;
    w = span_dim + 2 * mirror_clearance;
    t = mirror_thickness + 2 * mirror_clearance;
    throat = channel_lip + 5;
    dir = (open_edge == "front") ? 1 : -1;
    over = 1;  // run the cut past the front face; a flush cut is degenerate

    translate([0, 0, over/2])
        cube([l, w, t + over], center = true);
    translate([dir * (l/2 + throat/2 - 0.01), 0, over/2])
        cube([throat, w, t + over], center = true);
}

module mirror_seat(open_edge = "back") {
    difference() {
        linear_extrude(frame_t, center = true)
            rrect(frame_fold, frame_span, corner_r);
        translate([0, 0, mirror_backing / 2])
            seat_pocket(open_edge);
    }
}

// Half-space covering everything in front of a seat's back face, less a
// small merge depth. Subtract it from any support so the support stops
// inside the mirror's backing -- a solid weld, with nothing reaching the
// pocket floor or the reflective face.
module past_seat_back(P, phi) {
    translate(P)
        rotate([0, phi, 0])
            translate([-BIG/2, -BIG/2, -frame_t/2 + joint_merge])
                cube(BIG);
}

// ---------------------------------------------------------------------
// Stem faceplate mount: slotted holes so the bracket tolerates variation
// in faceplate bolt spacing.
// ---------------------------------------------------------------------

module mount_slot() {
    hull()
        for (sx = [-1, 1])
            translate([sx * slot_play/2, 0])
                circle(d = faceplate_bolt_dia);
}

module faceplate_mount() {
    plate_l = faceplate_spacing_x + slot_play + 3 * faceplate_bolt_dia;
    plate_w = faceplate_spacing_y + 3 * faceplate_bolt_dia;

    difference() {
        linear_extrude(mount_plate_thickness, center = true)
            rrect(plate_l, plate_w, corner_r);
        for (x = [-faceplate_spacing_x/2, faceplate_spacing_x/2],
             y = [-faceplate_spacing_y/2, faceplate_spacing_y/2])
            translate([x, y, 0])
                linear_extrude(mount_plate_thickness + 2, center = true)
                    mount_slot();
    }
}

// Tapered riser from the mount up to the back of a tilted mirror seat.
// Built long, then cut off against that seat's back plane, so it meets the
// plate at a clean angled joint instead of spearing through the face.
module riser_to(P, phi) {
    difference() {
        hull() {
            translate([0, 0, mount_plate_thickness/2])
                linear_extrude(0.1) rrect(riser_l, riser_w, corner_r);
            translate([0, 0, P[2] + frame_fold/2])
                linear_extrude(0.1) rrect(riser_l * 0.75, riser_w * 0.75, corner_r);
        }
        past_seat_back(P, phi);
    }
}

// ---------------------------------------------------------------------
// Assemblies
// ---------------------------------------------------------------------

module test_rig() {
    faceplate_mount();
    riser_to(P1, phi_single);
    translate(P1) rotate([0, phi_single, 0]) mirror_seat("back");
}

module two_mirror_rig() {
    // Mirrors are placed by the traced ray path: in along d_in to M1 at P1,
    // up along d_mid to M2 at P2, out along d_out. Rails run outside the
    // mirrors' side edges so nothing sits in the optical corridor, and both
    // seats come off one printed part so their roll axes stay parallel --
    // the ~0.5 deg tolerance the design notes call for.
    faceplate_mount();
    riser_to(P1, phi1);

    translate(P1) rotate([0, phi1, 0]) mirror_seat("back");
    translate(P2) rotate([0, phi2, 0]) mirror_seat("front");

    x_rail = frame_fold/2 - corner_r;
    // Slight overlap rather than exact tangency at the plate's side face:
    // tangent surfaces are a degenerate contact and render as z-fighting.
    y_out  = frame_span/2 + rail_dia/2 - 0.5;
    y_in   = frame_span/2 - rail_inset;   // ear bites into the seat's outer lip

    // M2 is flipped relative to M1, so its local +X points the other way in
    // world space. Pair each rail with the far seat's nearer end, or the
    // rails cross through the middle of the optical corridor.
    flip = ([cos(phi1), 0, -sin(phi1)] * [cos(phi2), 0, -sin(phi2)] < 0) ? -1 : 1;

    for (sy = [-1, 1], sx = [-1, 1]) {
        a1 = seat_pt(P1, phi1, sx * x_rail, sy * y_out);
        a2 = seat_pt(P2, phi2, flip * sx * x_rail, sy * y_out);

        rod(a1, a2, rail_dia);

        // Ears blending each rail into the seat edge, tapered down to just
        // under the plate's own thickness so nothing stands proud of a
        // mirror face.
        taper_rod(a1, seat_pt(P1, phi1, sx * x_rail, sy * y_in),
                  rail_dia, frame_t - 0.6);
        taper_rod(a2, seat_pt(P2, phi2, flip * sx * x_rail, sy * y_in),
                  rail_dia, frame_t - 0.6);
    }
}

if (mirror_count == 1)
    test_rig();
else
    two_mirror_rig();
