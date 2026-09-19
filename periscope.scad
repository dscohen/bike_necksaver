// periscope.scad -- enclosed bike periscope box.
//
// Background / derivation: see docs/design-notes.md.
//
// What this is: a light-tight box that hangs below and ahead of the stem,
// in the out-front light zone above the tire. You look down into a window
// on its top-back face; the view of the road ahead comes out a window on
// its front face. Two mirrors inside, so the image is upright.
//
// Layout (side view, rider on the left, X = forward, Z = up):
//
//        eye ----> \ 60 deg down
//                   \
//   [stem faceplate]  \ entry window
//        | plate       \|
//        |            +--M1  (near-vertical, faces the rider)
//        +------------|   |
//          box        |   |    ray goes DOWN-BACK to M2
//                    M2   |
//                     |   |==> exit window, looking forward at the road
//                     +---+
//
// The ray between the mirrors runs down-and-back (mid_elevation < 0).
// Running it up instead is also valid optically but stands a mast in the
// rider's face -- see docs/design-notes.md for why this is the layout.
//
// Coordinates: X forward, Y left, Z up. World origin = center of the stem
// faceplate's front face. Everything in the fold plane is drawn as 2D
// (x, z) and extruded along Y, which is what makes the box a clean prism.
//
// Mirrors are NOT custom-cut: standard 160 x 100 mm acrylic tiles slide in
// through slots in the +Y side wall, edges captured in grooves, and are
// held by printed caps. The 160 mm side runs across the beam (wide view
// of the road), the 100 mm side takes the fold.

/* [Optics] */
mirror_count    = 2;    // [2, 1]  2 = the periscope; 1 = inverting test box
theta           = 60;   // deg, head pitch below horizontal
mid_elevation   = -135; // deg, ray between mirrors (negative = down-back, see notes)
eye_to_device   = 500;  // mm, eye to entry window, for the FOV estimate
target_aperture = 75;   // mm, cap on vertical aperture

/* [Mirror stock] */
mirror_stock_length = 160;
mirror_stock_width  = 100;
mirror_thickness    = 3;      // CONFIRM against the actual tile
mirror_clearance    = 0.4;    // per side, slide fit in the slot
fold_axis           = "width"; // ["width","length"] which side takes the fold

/* [Box] */
wall         = 2.4;  // mm, top/bottom/front/back walls
side_wall    = 5;    // mm, the two side walls (carry the mirror grooves)
groove_depth = 2.5;  // mm, how far mirror edges sit into each side wall
window_depth = 30;   // mm, hood in front of each mirror before its window
mirror_gap   = 0;    // mm between mirror centers; 0 = auto (just clears)
cap_t        = 2;    // mm, cap plate thickness
cap_lip      = 4;    // mm, cap overlap around the slot

/* [Placement, relative to the faceplate front face center] */
box_x = 112;   // mm forward to mirror 1
box_z = -75;   // mm down to mirror 1 (negative = below)

/* [Stem faceplate plate -- vertical, bolts run fore-aft] */
mount_t             = 6;
faceplate_bolt_dia  = 5.5;
faceplate_spacing_h = 40;  // mm, left-right bolt spacing
faceplate_spacing_v = 32;  // mm, up-down bolt spacing
slot_play           = 6;   // mm, extra left-right travel per slot

/* [Output] */
part         = "assembly"; // ["assembly","box","caps"]
show_mirrors = true;       // preview only (not exported)
show_beam    = true;       // preview only (not exported)
cutaway      = false;      // slice the assembly at y=0 to see inside

$fn = 48;

// ---------------------------------------------------------------------
// 2D helpers.  Points are [x, z].
// ---------------------------------------------------------------------

function unit2(v) = v / norm(v);
function perp2(v) = [-v[1], v[0]];
function ang2(v)  = atan2(v[1], v[0]);

// Extrude a 2D (x, z) profile along Y from y0 to y1.
module xz(y0, y1)
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();

// Rectangle centered on c, long axis perpendicular to n.
module slab2d(c, n, len, t)
    translate(c) rotate(ang2(perp2(n))) square([len, t], center = true);

// Rectangle starting at c, running `len` along d, `w` wide.
module bar2d(c, d, len, w)
    translate(c) rotate(ang2(d)) translate([0, -w/2]) square([len, w]);

module rect2d(p0, p1)
    translate([min(p0[0], p1[0]), min(p0[1], p1[1])])
        square([abs(p1[0] - p0[0]), abs(p1[1] - p0[1])]);

module rrect(l, w, r)
    hull() for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * (l/2 - r), sy * (w/2 - r)]) circle(r = r);

// ---------------------------------------------------------------------
// Ray path and mirrors (box coordinates: mirror 1 at the origin).
// ---------------------------------------------------------------------

two = (mirror_count == 2);

d_in  = [cos(theta), -sin(theta)];
d_out = [1, 0];
d_mid = [cos(mid_elevation), sin(mid_elevation)];

n1 = two ? unit2(d_mid - d_in) : unit2(d_out - d_in);
n2 = unit2(d_out - d_mid);
t1 = perp2(n1);
t2 = perp2(n2);

inc1 = acos(-(d_in * n1));
inc2 = two ? acos(-(d_mid * n2)) : 0;

fold_dim = (fold_axis == "width") ? mirror_stock_width  : mirror_stock_length;
span_dim = (fold_axis == "width") ? mirror_stock_length : mirror_stock_width;

aperture = two
    ? min(target_aperture, fold_dim * cos(inc1), fold_dim * cos(inc2))
    : min(target_aperture, fold_dim * cos(inc1));

h1 = fold_dim / 2 + mirror_clearance;          // half-length of a mirror slot
mt = mirror_thickness + 2 * mirror_clearance;  // slot thickness

// Auto gap: the exit beam has to pass under mirror 1's lower end. The margin
// is kept under 2*wall so the two shell lobes merge instead of leaving a slit.
gap_auto = !two ? 0
         : (d_mid[1] < 0) ? (h1 * abs(t1[1]) + aperture/2 + 4) / (-d_mid[1])
         : fold_dim * 1.3;
gap = two ? ((mirror_gap > 0) ? mirror_gap : gap_auto) : 0;

c1 = [0, 0];
c2 = gap * d_mid;
cL = two ? c2 : c1;

plate_w = faceplate_spacing_h + slot_play + 3 * faceplate_bolt_dia;
plate_h = faceplate_spacing_v + 3 * faceplate_bolt_dia;

// Where the neck meets the mount plate (box coords).
att_x = [-box_x + mount_t - 2, -box_x + mount_t + 8];
att_z = [-plate_h/2 - box_z, plate_h/2 - 4 - box_z];

// The entry snout has to reach up to the mount plate so the neck has a wall
// to weld to. Whichever is longer: the requested hood, or that.
snout_needed = (att_z[0] + 6 + (aperture/2) * cos(theta)) / sin(theta);
snout = max(window_depth, snout_needed);

entry_c = c1 - snout * d_in;
exit_c  = [c1[0] + h1 * abs(t1[0]) + wall + 8, cL[1]];

cavity_y = span_dim - 2 * groove_depth;
outer_y  = cavity_y + 2 * side_wall;

// ---------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------

entry_back = entry_c - (aperture/2) * [sin(theta), cos(theta)];
function beam_back_x(z) = entry_back[0] - (z - entry_back[1]) / tan(theta);
plate_clear = beam_back_x(plate_h/2 - box_z) - (mount_t - box_x);
box_clear   = beam_back_x(att_z[1]) - (att_x[1] + wall);

// Print envelope from the profile's extreme points.
env_pts = concat(
    [c1 + h1 * t1, c1 - h1 * t1],
    two ? [c2 + h1 * t2, c2 - h1 * t2] : [],
    [entry_c + (aperture/2) * perp2(d_in), entry_c - (aperture/2) * perp2(d_in)],
    [exit_c + [0, aperture/2], exit_c - [0, aperture/2]],
    [[att_x[0], att_z[0]], [att_x[0], att_z[1]]]);
env_x = [min([for (p = env_pts) p[0]]) - wall, max([for (p = env_pts) p[0]]) + wall];
env_z = [min([for (p = env_pts) p[1]]) - wall, max([for (p = env_pts) p[1]]) + wall];

echo("---- Bike periscope box ----");
echo(str("print envelope ", env_x[1] - env_x[0], " long x ", outer_y, " wide x ",
         env_z[1] - env_z[0], " tall (mm); hangs from ", box_z + env_z[1], " to ",
         box_z + env_z[0], " mm relative to the faceplate center, reaching ",
         box_x + env_x[1], " mm forward of it"));
echo(str("head pitch ", theta, " deg; mirrors ", mirror_count,
         "; tile ", mirror_stock_length, "x", mirror_stock_width, "x", mirror_thickness,
         " mm, ", fold_dim, " mm side on the fold"));
echo(str("M1 incidence ", inc1, " deg", two ? str(", M2 incidence ", inc2, " deg") : ""));
echo(str("aperture ", aperture, " mm  ->  FOV ", atan(aperture / eye_to_device),
         " deg vertical x ", atan(cavity_y / eye_to_device), " deg horizontal"));
if (two) echo(str("mirror gap ", gap, " mm", (mirror_gap > 0) ? "" : " (auto)",
                  "; M2 is ", -c2[0], " mm behind and ", -c2[1], " mm below M1"));
echo(str("entry beam clears the plate's top corner by ", plate_clear,
         " mm and the box's back corner by ", box_clear, " mm"));
if (plate_clear < 5 || box_clear < 5)
    echo("WARNING: entry beam grazes the mount. Increase box_x or reduce the drop (box_z).");
if (two && inc2 > 65 || inc1 > 65)
    echo("WARNING: grazing incidence -- aperture is collapsing. Move mid_elevation toward -135.");
if (mirror_count == 1)
    echo("NOTE: one mirror -- the image is vertically INVERTED. This is the adaptation test box only.");

// ---------------------------------------------------------------------
// Box
// ---------------------------------------------------------------------

module mirror_slot2d(c, n) slab2d(c, n, 2 * h1, mt);

// Half-plane on the reflective (+n) side of a mirror at c.
module front_of(c, n)
    translate(c) rotate(ang2(perp2(n))) translate([-600, -600]) square([1200, 600]);

// The cavity is the beam itself: one corridor per leg, each clipped by the
// mirror plane(s) at its ends so it covers the beam's full footprint on the
// mirror, plus a pocket around each mirror (they are longer than the beam
// is wide, because of foreshortening). No convex hull -- the box follows
// the Z of the ray path instead of ballooning around it.
module cavity2d() {
    intersection() {
        bar2d(entry_c, d_in, snout + 2 * h1, aperture);
        front_of(c1, n1);
    }
    if (two) intersection() {
        bar2d(c1 - h1 * d_mid, d_mid, gap + 2 * h1, aperture);
        front_of(c1, n1);
        front_of(c2, n2);
    }
    intersection() {
        bar2d(cL - h1 * d_out, d_out, exit_c[0] - cL[0] + h1 + 2, aperture);
        front_of(cL, two ? n2 : n1);
    }
    mirror_slot2d(c1, n1);
    if (two) mirror_slot2d(c2, n2);
}

// Shell = walls around the cavity, plus a solid neck reaching back to the
// mount plate. The neck is drawn generously long; the cavity subtraction
// and the entry-beam cut trim it flush, so it cannot intrude on the view.
module shell2d() {
    offset(r = wall) cavity2d();
    rect2d([att_x[0], att_z[0]], [att_x[0] + 45, att_z[1]]);
}

// Beam corridors, run long so they punch out through whichever wall they hit.
module entry_cut2d() bar2d(c1, -d_in, 400, aperture);
module exit_cut2d()  bar2d(cL, d_out, 400, aperture);

module box() {
    difference() {
        xz(-outer_y/2, outer_y/2) shell2d();
        xz(-cavity_y/2, cavity_y/2) cavity2d();
        // Mirror slots: groove into the -Y wall, right through the +Y wall.
        xz(-cavity_y/2 - groove_depth, outer_y/2 + 1) mirror_slot2d(c1, n1);
        if (two) xz(-cavity_y/2 - groove_depth, outer_y/2 + 1) mirror_slot2d(c2, n2);
        xz(-cavity_y/2, cavity_y/2) entry_cut2d();
        xz(-cavity_y/2, cavity_y/2) exit_cut2d();
    }
}

// Cap: plate over the slot on the +Y wall, with a tab that fills the outer
// part of the slot so the mirror is held to the same depth as the -Y groove.
module cap(c, n) {
    xz(outer_y/2, outer_y/2 + cap_t) offset(r = cap_lip) mirror_slot2d(c, n);
    xz(cavity_y/2 + groove_depth, outer_y/2 + 0.01) offset(r = -0.25) mirror_slot2d(c, n);
}

module caps_in_place() {
    cap(c1, n1);
    if (two) cap(c2, n2);
}

module caps_flat() {
    // Laid on the bed, plate down, tab up.
    for (i = [0 : (two ? 1 : 0)])
        translate([i * (2 * h1 + 2 * cap_lip + 10), 0, 0])
            rotate([-90, 0, 0])
                translate([0, -(outer_y/2 + cap_t), 0])
                    translate([-(i == 0 ? c1[0] : c2[0]), 0, -(i == 0 ? c1[1] : c2[1])])
                        cap(i == 0 ? c1 : c2, i == 0 ? n1 : n2);
}

// ---------------------------------------------------------------------
// Mount: vertical plate on the faceplate front, slotted for bolt spacing.
// ---------------------------------------------------------------------

module mount_slot2d()
    hull() for (s = [-1, 1]) translate([s * slot_play/2, 0]) circle(d = faceplate_bolt_dia);

module mount_plate() {
    difference() {
        rotate([90, 0, 90]) linear_extrude(mount_t) rrect(plate_w, plate_h, 4);
        for (sy = [-1, 1], sz = [-1, 1])
            translate([-1, sy * faceplate_spacing_h/2, sz * faceplate_spacing_v/2])
                rotate([90, 0, 90]) linear_extrude(mount_t + 2) mount_slot2d();
    }
}

// ---------------------------------------------------------------------
// Preview-only ghosts (the % modifier keeps them out of exports).
// ---------------------------------------------------------------------

module ghosts() {
    if (show_mirrors) {
        %color("silver") xz(-span_dim/2, span_dim/2) slab2d(c1, n1, fold_dim, mirror_thickness);
        if (two) %color("silver") xz(-span_dim/2, span_dim/2) slab2d(c2, n2, fold_dim, mirror_thickness);
    }
    if (show_beam) {
        %color("gold", 0.25) xz(-cavity_y/2 + 1, cavity_y/2 - 1) bar2d(c1, -d_in, 220, aperture);
        if (two) %color("gold", 0.25) xz(-cavity_y/2 + 1, cavity_y/2 - 1) bar2d(c1, d_mid, gap, aperture);
        %color("gold", 0.25) xz(-cavity_y/2 + 1, cavity_y/2 - 1) bar2d(cL, d_out, exit_c[0] - cL[0] + 80, aperture);
    }
}

// ---------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------

module assembly() {
    mount_plate();
    translate([box_x, 0, box_z]) {
        box();
        caps_in_place();
    }
}

if (part == "assembly") {
    if (cutaway)
        difference() { assembly(); translate([-500, 0, -500]) cube(1000); }
    else
        assembly();
    translate([box_x, 0, box_z]) ghosts();
} else if (part == "box") {
    box();
} else {
    caps_flat();
}
