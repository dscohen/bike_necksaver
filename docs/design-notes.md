# Design notes

## Problem

Riding with the head pitched down — aero position, or a rider who can no
longer hold cervical extension for the full ride (Shermer's neck-type
fatigue) — puts the road out of the useful field of view. The head has to
come back up to see, which defeats the point.

## Why the obvious fixes don't work

- **Eyewear / helmet / fit adjustments** (lens geometry, pantoscopic tilt,
  visor position, saddle/bar position, neck endurance work) are the right
  first things to try if the head-down position is only partial or
  fatigue-driven, and should be ruled out before building anything. This
  project is for the case where the head genuinely can't come up far enough,
  or the position is deliberately aero and non-negotiable.
- **Belay glasses** use a prism to bend the line of sight ~90° so a
  level-headed belayer sees the zenith. On a bike this splits the scene
  badly (prism view of the road, unaided peripheral view of the ground
  underfoot) and the bend is fixed near 90° — partial head-down overshoots
  into sky. Field of view and image quality are also poor (soft acrylic,
  chromatic fringing, narrow central field, no stereopsis).
- **Commercial bike periscopes** don't really exist as a bought product.
  The Pedi-Scope was a 2015 Kickstarter that never reached production. The
  VeloView Prism is a small two-person operation, stock is inconsistent,
  and their own testimonials note a limited field of view.

## The optics

### A single reflection always inverts the image

Set up the geometry: gaze pitched down by θ, scene straight ahead, so the
device must deviate the line of sight by exactly θ (deviation and head
pitch are the same angle, both measured from horizontal).

For a single mirror with normal **n** = (sin(θ/2), 0, cos(θ/2)), the
reflection matrix **M** = **I** − 2**nn**ᵀ works out to:

```
M = [ cosθ   0  −sinθ ]
    [   0    1     0  ]
    [−sinθ   0  −cosθ ]
```

Take a scene point in direction (1, b, e) — b = left/right offset, e =
elevation. Projecting the reflected direction M·(1,b,e) onto the head's own
up/left axes:

```
up-component   = −e
left-component =  b
```

Left–right is preserved, vertical is inverted, and **the θ terms cancel
completely** — the inversion is exact at any head pitch, not just at 90°.
Near road ends up at the top of the field, horizon at the bottom, optic
flow running backwards. Steering cues (left/right) stay correct, which
arguably makes it more insidious rather than less.

### Belay glasses get away with it because the head doesn't rotate

Run the same math with head-up fixed at (0,0,1) instead of composing a
rotation — the offsets come out preserved. A belayer's head stays level;
the prism does the full deviation on its own. A cyclist's head rotating
down, combined with a reflection, is what composes into inversion. Same
optic, different mounting, opposite outcome.

### A prism doesn't save you either

Parity is set by **reflection count**, not by whether the component is a
mirror or glass. A plain right-angle prism used in deviation mode has
exactly one total-internal-reflection bounce (in one leg, TIR off the
hypotenuse, out the other leg) — it inverts identically to a 45° mirror.
Only an even-reflection prism (Porro) or a roof prism (Amici) corrects it.
(If evaluating a commercial unit like VeloView, the question worth asking
the maker is how many reflections are in the optic.)

### Mirror vs. prism as the fold element

A first-surface mirror at 45° gives a wider acceptance angle than a prism
of the same aperture — refraction at a prism's entry face compresses the
field by roughly 1/n, plus edge dispersion. A prism's only advantages are
that it's sealed against rain and self-supporting. This project uses
mirrors.

### Field of view

FOV ≈ aperture ÷ eye-to-device distance. A 75mm optic at ~500mm gives
about 8.5°, i.e. roughly 3m of road width at 20m out. Aperture is the only
real lever on FOV — it's why the Pedi-Scope used the whole handlebar width.

## Two-mirror correction

Two mirrors, net deviation = 2 × dihedral angle between them, so:

```
dihedral = θ / 2
i1 − i2 = θ / 2        (i1, i2 = each mirror's incidence angle)
clear length = aperture / cos(incidence)
```

Keep both incidence angles under ~55° or foreshortening makes the mirrors
enormous. This is what `periscope.scad`'s `mirror_count = 2` path
computes.

### What it costs

- **Volume roughly triples.** Example: θ=60°, i1=45°, 80mm aperture gives
  M1 ≈ 113mm, M2 ≈ 83mm clear length, stacked ~90mm apart — call it
  140×130×150mm hanging off the front of the bar.
- **Weight**, hence thin (3mm) mirror stock rather than thicker acrylic —
  two 6mm mirrors at that size is ~200g on a long moment arm; 3mm gets
  that to ~100g, with the printed frame supporting the mirror at three
  points rather than leaving it cantilevered.
- **Throughput.** Two bounces at ordinary ~88% aluminized reflectance is
  77% overall; a high-reflectance coating (e.g. Alanod MIRO-SILVER, ~98%)
  gets that back to ~96%.
- **Roll alignment is the build risk.** The two mirrors' hinge axes must
  stay parallel to within ~0.5°, or the horizon comes back tilted while
  steering — worse than no device at all. `periscope.scad` prints both
  mirror seats from one shared datum/orientation in the same part rather
  than assembling them separately, specifically to avoid this failure
  mode. Only the second mirror's pitch is meant to be field-adjustable.

## Why the mirror is off-the-shelf stock, not custom-cut

The math above derives an *ideal* mirror size from the target aperture and
θ. In practice, sourcing and replacing a custom-cut mirror is the annoying
part of the build. `periscope.scad` instead takes a standard 160mm ×
100mm (6.3" × 3.94") acrylic mirror tile as a fixed input, sizes the
optical aperture to whatever that stock allows (clamping and warning if
the ideal size would need something larger), and holds the mirror in a
captured, slide-in channel so it drops in without glue and can be swapped.

## Mount

Angular vibration maps 1:1 onto a narrow field, so mount rigidity matters
more than anything else in the build — a stem faceplate or aerobar bridge,
not the bar tops or anything compliant. This project targets the stem
faceplate. Because faceplate bolt spacing varies between stems, the
mounting holes are slots with adjustment play rather than fixed round
holes at a fixed spacing.

## Known limitation

There's a blind band between the near edge of the optic and where unaided
downward vision picks up, so potholes and near obstacles arrive with very
little warning. Treat this as a straight-road, steady-effort tool
(time trial, aero position, headwind grinding), not a general-purpose
substitute for looking up.

## Build / test plan

1. Build the **v1 single-mirror test rig** first (`mirror_count = 1`).
   It's cheap, small, and answers the one question the math can't: whether
   you can adapt to the vertical image inversion. Prism/mirror adaptation
   is a real, sometimes-fast perceptual effect — this is the way to find
   out rather than guess.
2. Tape it on and ride a quiet road at low speed (~10 mph) before trusting
   it in traffic.
3. Use the test rig to measure your actual head pitch angle (θ) in the
   position you actually ride in — this sets every angle in the v2 build.
4. If the inversion isn't adaptable, or you want the corrected image, move
   to the **v2 two-mirror build** (`mirror_count = 2`) using the measured
   θ.

## Sources

- Belay glasses — Wikipedia
- Pedi-Scope — BikeRadar, New Atlas
- VeloView Prism — manufacturer site
