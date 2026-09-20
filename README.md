# bike_necksaver

A 3D-printable bike periscope: an enclosed two-mirror box that hangs
below and ahead of the stem and lets you see the road while riding with
your head pitched down (aero position, or a neck that can't hold
extension for the whole ride). You look down into a hooded window on
top; the view of the road ahead comes out a window on the front. Two
reflections, so the image is upright. See
[docs/design-notes.md](docs/design-notes.md) for the optics — why a
single mirror always inverts the image, why belay glasses don't disprove
that, why buying a prism instead is a dead end, and why the box hangs
*below* the bars rather than standing up in front of your face.

## Status

The two-mirror periscope (`mirror_count = 2`) is the design and the
default. Nothing has been printed yet.

- **Test box** (`mirror_count = 1`). Not a candidate design — one
  reflection, so the image is vertically inverted. It exists to answer the
  one question the math can't (whether you can *adapt* to the inversion)
  and to measure your real head-pitch angle θ, which sets every dimension
  of the real thing.
- **The periscope** (`mirror_count = 2`). Waiting on a measured θ.

## Before you print anything

Four inputs in `periscope.scad` are currently guesses, and every dimension
of the box follows from them. Work through these in order — the first
three are free, and the fourth costs about a dollar.

**1. Measure your head pitch (θ).** No printing needed. Have someone shoot
a phone video from directly beside you while you ride your actual
position, freeze a frame, and measure the angle of your line of sight
below horizontal. Set `theta` to that. Everything else in the model is
derived from it, so a guess here means reprinting.

**2. Caliper your stem faceplate.** Measure both bolt spacings — left-right
and top-bottom — and set `faceplate_spacing_h` and `faceplate_spacing_v`.
Note the mounting slots only flex left-right (`slot_play`, ±3mm default);
vertical spacing has no adjustment, so it has to be right.

**3. Buy the mirror tiles first and measure them.** Set `mirror_thickness`
to what you actually have, not the assumed 3mm. Too thin and the mirror
rattles in its slot; too thick and it won't go in.

**4. Build the cardboard mockup.** This is the step worth insisting on —
it costs a sheet of cardboard and half an hour, against a ~133 × 167 ×
235 mm print if you get it wrong.

```
openscad -o template.svg -D 'part="template"' periscope.scad
```

Print that **at 100% / "Actual Size" — not "Fit to Page"** (A4, or Letter
with 0.25in margins). Measure the printed ruler: if it isn't 100mm, your
printer rescaled it and the template is useless. Then spray-glue it to
cardboard, cut **two** identical side panels, space them the distance
printed on the template (155mm by default), and tape your actual mirror
tiles along the M1 and M2 lines with the reflective faces toward the light
path. The thin lines are the beam — keep them clear; there's nothing to
cut out, since the mockup's edges are already open.

Then hold it against the bike and answer three questions the CAD can't:

- **Does it physically fit?** The box hangs ~208mm below the faceplate and
  reaches ~131mm forward, which puts it over the front tire. Check tire
  clearance, cable routing, and whether it fouls your knees out of the
  saddle.
- **Can you see anything useful?** Get in your riding position and look
  down into the entry. You should see the road ahead, right way up.
- **Is the blind band tolerable?** See Known limitations below.

Only then print.

## Bill of materials

- 2x (or 1x for the test box) **acrylic mirror tile, 160mm × 100mm
  (6.3" × 3.94"), ~3mm thick** — off-the-shelf, no cutting. Confirm the
  actual thickness of what you buy against `mirror_thickness`.
- 3D-printed box + 2 caps (`periscope.scad`). PETG or ASA over PLA for
  outdoor use. Print the box in black, or paint the inside matte black —
  it's a light tube and glare off the walls is the enemy.
- Reuses your stem's own faceplate bolts (M5 typical; some are M4 — check).

## Building it

Requires [OpenSCAD](https://openscad.org/). With the file open, the
console prints the derived optics every render — incidence angles,
aperture, field of view, mirror separation, and how far the entry beam
clears the mount. Read those before printing anything.

```
openscad -o periscope.stl periscope.scad                       # the box
openscad -o caps.stl      periscope.scad -D 'part="caps"'      # the two caps
openscad -o testbox.stl   periscope.scad -D mirror_count=1     # the test box
openscad -o template.svg  periscope.scad -D 'part="template"'  # 1:1 paper template
```

**Print orientation matters.** The box is a straight extrusion along one
axis, so laid on a side wall it prints with **no supports at all** — every
layer is the same cross-section. Tell your print service to orient it that
way (167mm tall, 133 × 235mm footprint). Printed upright instead, it needs
supports inside a sealed tube that you cannot reach through a 61mm window.

Set `cutaway = true` in the file (preview mode, F5) to see inside; the
mirrors and the beam path are drawn as ghosts in preview and never
exported.

Parameters that matter, at the top of `periscope.scad`:

| Parameter | Meaning |
|---|---|
| `theta` | Your head pitch below horizontal, degrees. Measure it with the test box. |
| `mid_elevation` | Direction of the ray between the two mirrors. Negative runs it down-and-back so the box hangs under the stem (default −135°). See the notes before touching this. |
| `fold_axis` | Which side of the tile takes the fold. `"width"` (default) puts the 160mm side across the beam — wide view of the road, compact box. `"length"` gives more vertical aperture and a much bigger box. |
| `box_x` / `box_z` | Where mirror 1 sits relative to the faceplate: forward and down. The console warns if the entry beam grazes the mount. |
| `mirror_gap` | Mirror separation; `0` auto-sizes it to the minimum that lets the exit beam pass under mirror 1. |
| `faceplate_spacing_h` / `_v` / `slot_play` | Your stem's bolt spacing and how much slot travel to allow. |
| `wall` / `side_wall` / `groove_depth` | Box wall thicknesses and how deep the mirror edges seat. |

## Assembly

The mirrors slide in from the side: each has a slot straight through the
+Y side wall and a matching groove in the opposite wall, so both mirrors
are located by the same printed part and their roll axes stay parallel.
Reflective face toward the windows. A printed cap covers each slot and
its tab fills the outer part of the slot, holding the mirror to the same
depth as the far groove — no glue anywhere. The mount is a vertical plate
that goes under your stem's faceplate bolts; the holes are slots so it
tolerates a range of bolt spacings.

## Known limitations

- There's a blind band between the optic's near edge and where your
  unaided downward vision picks up — potholes and close obstacles arrive
  with little warning. Straight-road, steady-effort tool; not a substitute
  for looking up in traffic.
- The exit window faces forward just above the front tire: it will
  collect spray. A short printed hood, or just wiping it, is the answer.
- The stock mirrors are longer than the beam needs at the second mirror,
  which is why the box bulges at the corners. That's the cost of not
  cutting mirrors.
