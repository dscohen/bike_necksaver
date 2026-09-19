# bike_necksaver

A 3D-printable bike periscope: a mirror-based device that lets you see the
road while riding with your head pitched down (aero position, or a neck
that can't hold extension for the whole ride). See
[docs/design-notes.md](docs/design-notes.md) for the full optics
derivation — why belay glasses and prisms don't work for this, why a
single mirror inverts the image, and the math behind the two-mirror
corrected version.

## Status

- **v1 — single-mirror test rig.** Answers the one question the math
  can't: whether you can adapt to the vertical image inversion a single
  reflection produces. Also used to measure your real head-pitch angle
  (θ), which sets every dimension in v2.
- **v2 — two-mirror periscope.** Corrects the inversion, at the cost of
  roughly 3x the volume and tighter build tolerances. Not yet built —
  waiting on a measured θ from the v1 rig. Be aware going in that a
  corrected-vision periscope is necessarily *tall* (mirror 2 ends up well
  above mirror 1); keeping it low and forward drives the second mirror to
  grazing incidence and collapses the field of view. The design notes work
  through why.

## Bill of materials

- 1x (v1) or 2x (v2) **acrylic mirror tile, 160mm × 100mm (6.3" × 3.94"),
  ~3mm thick** — off-the-shelf, no custom cutting. Confirm the actual
  thickness of whatever you buy against `mirror_thickness` in
  `periscope.scad`.
- M5 (or M4, check your stem) bolts for the faceplate mount — reuses your
  stem's existing faceplate bolts/holes.
- 3D printed housing (`periscope.scad`), PETG or similar recommended over
  PLA for outdoor/vibration durability.

## Building the housing

Requires [OpenSCAD](https://openscad.org/).

```
openscad periscope.scad
```

Key parameters (edit at the top of `periscope.scad`, or override with
`-D name=value` on the command line):

| Parameter | Meaning |
|---|---|
| `mirror_count` | `1` for the test rig, `2` for the corrected build |
| `theta` | Your head pitch below horizontal, in degrees |
| `mid_elevation` | Elevation of the ray between the two mirrors — the main shape knob. Higher = more aperture and field of view, but a taller device. See the design notes. |
| `fold_axis` | Which mirror dimension takes the fold: `"length"` (160mm, max aperture, ~330mm tall) or `"width"` (100mm, smaller aperture, ~233mm tall) |
| `eye_to_device` | Distance from your eye to the first mirror, mm |
| `target_aperture` | Desired optical aperture, mm (clamped to what the mirror stock allows — check the console output) |
| `mirror_stock_length` / `mirror_stock_width` / `mirror_thickness` | The mirror tile you're actually using |
| `mirror_gap` | Mirror separation along the folded path; `0` auto-sizes it so the plates don't intersect |
| `faceplate_spacing_x` / `faceplate_spacing_y` | Your stem's nominal faceplate bolt spacing |
| `slot_play` | Extra travel added to the mounting slots to cover stem-to-stem variance |

Rendering prints the derived optics (incidence angles, ideal vs.
achievable aperture/mirror size, resulting FOV) to the console — check
those numbers before printing. Export an STL with:

```
openscad -o periscope.stl periscope.scad -D mirror_count=1
```

## Assembly

The mirror slides into a captured channel on one open edge — no glue,
and it's swappable. A small printed clip closes the open edge after
insertion. The mount holes are slots, not fixed round holes, so the same
bracket should fit stems with slightly different faceplate bolt spacing
than the nominal values above; if it doesn't, adjust
`faceplate_spacing_x/y` and re-render.

## Known limitation

There's a blind band between the optic's near edge and where your
unaided downward vision picks up — potholes and close obstacles arrive
with little warning. This is a straight-road, steady-effort tool (time
trial, aero position, headwind), not a substitute for looking up in
traffic. See design notes for more.
