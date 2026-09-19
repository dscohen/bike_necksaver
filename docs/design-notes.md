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

### Belay glasses do NOT get away with it — correcting an earlier claim

An earlier version of these notes claimed the belayer is exempt because
their head stays level, and that it's the cyclist's head *rotation*
composing with the reflection that causes the inversion. **That is wrong,
and it matters, because it was being used as evidence that a single fold
can be made to work if you just mount it cleverly. It can't.**

Head orientation has nothing to do with parity. A single reflection
inverts the image in the plane of the fold, full stop. Rotating your head
changes what you *call* "up"; it does not change what the mirror does to
the ray bundle. Running the belayer's geometry properly (head level, gaze
horizontal, prism deviating the sightline up to a climber at 60°
elevation) and comparing against the craned-neck view it replaces, the
image comes out inverted by exactly the same amount as the bike case.

The everyday check that settles it is a **car rear-view mirror**. One
reflection, and text comes back mirror-reversed left-to-right but
perfectly upright — because that fold happens in the *horizontal* plane,
so the horizontal axis flips and the vertical survives. Now rotate that
geometry 90°: belay glasses (and a bike periscope) fold in the *vertical*
plane, so left–right survives and **up–down flips**. Same optic, same
rule, different axis.

So what about real belay glasses, which by all accounts show an upright
climber? If they do, it is because the optic contains an **even number of
reflections** — a Porro- or roof-type arrangement, not the single-TIR
right-angle prism assumed here — and not because of head posture. That's
a checkable fact about the hardware that these notes do not currently
know. It is the same question worth asking the maker of any commercial
unit (see below).

The practical consequence: there is no clever mounting that rescues a
single mirror. The v1 rig is purely an experiment in whether a rider can
*adapt* to an inverted image — not a candidate final design.

### A prism doesn't save you either

Parity is set by **reflection count**, not by whether the component is a
mirror or glass. A plain right-angle prism used in deviation mode has
exactly one total-internal-reflection bounce (in one leg, TIR off the
hypotenuse, out the other leg) — it inverts identically to a 45° mirror.
Only an even-reflection prism (Porro, penta, half-penta) or a roof prism
(Amici) corrects it. (If evaluating a commercial unit like VeloView, the
question worth asking the maker is how many reflections are in the optic.
Buying such a prism outright was investigated and rejected — see the dead
end section below.)

### Dead end: buying an even-reflection prism instead

Since two reflections is what buys an upright image, the obvious shortcut
is to buy a single component that already contains two — a penta,
half-penta, Amici roof, or Porro prism — and skip the two-mirror frame
entirely. This was investigated and rejected. Three independent reasons:

**1. Weight scales as aperture³.** This is the one that kills it. Glass
volume goes as the cube of the clear aperture, so useful apertures land in
kilograms:

| Aperture | FOV @ 500mm | Penta prism (N-BK7) | Two 3mm acrylic mirrors |
|---|---|---|---|
| 25mm | 2.9° | 53 g | 113 g |
| 50mm | 5.7° | 424 g | 113 g |
| 75mm | 8.5° | 1.4 kg | 113 g |
| 92mm | 10.4° | **2.6 kg** | 113 g |

The mirror pair reaches ~92mm of aperture for 113g of acrylic. Matching
that in glass means 2.6kg cantilevered off the handlebars.

**2. Nothing is manufactured at the needed size.** Edmund's penta prisms
stop at 50mm ($263–321). Half-pentas exist only at 10mm and 25mm. The
surplus market (Surplus Shed) tops out around a 34.5mm Amici roof at
$12.50 and Porros to ~52mm at ~$5 — cheap, but a fraction of the aperture.

**3. Prisms have fixed deviations.** Penta and Amici are 90°, half-penta
45°, Porro 180°. The deviation this device needs is whatever the rider's
head pitch actually turns out to be. Worse, a penta prism's defining
property is *constant* deviation — 90° regardless of how it's rotated —
which is the exact opposite of the tunability wanted here. The mirror
pair's dihedral can be set to the measured θ; a prism's cannot.

What a prism *would* genuinely buy, and it isn't nothing: factory-fixed
alignment, which removes the ~0.5° roll tolerance that is otherwise this
design's biggest build risk, plus weather sealing. Worth revisiting only
if the aperture requirement ever collapses.

**One conditional worth remembering:** if the v1 rig measures head pitch
near **45°**, a half-penta prism becomes an exact geometric match — 45°
deviation, two reflections, upright image, pre-aligned. The cost is
aperture: 25mm gives ~2.9° of field against ~10° from the mirrors.

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

Note that aperture is the mirror's *foreshortened* extent, not its
physical size: `aperture = mirror length × cos(incidence)`. See the
normal-tilt-vs-incidence section below before trusting any aperture
number.

## Two-mirror correction

Two mirrors, net deviation = 2 × dihedral angle between them, so:

```
dihedral = θ / 2
φ1 − φ2 = θ / 2        (φ1, φ2 = each mirror normal's tilt from vertical)
clear aperture = mirror length × cos(incidence)
```

### Normal tilt is not the angle of incidence

This bit is easy to get wrong, and getting it wrong silently inflates
every aperture number. The dihedral relation above is about the mirrors'
**normal tilts**. Foreshortening is about each mirror's **angle of
incidence**, which is a different angle. At θ=60° the single-mirror
solution has its normal tilted 30° from vertical but sits at **60°** of
incidence — so the real foreshortening is 2×, not the 1.15× you'd get by
plugging the tilt into the cosine.

The reliable way to get both is to stop reasoning in angles and trace the
rays. A mirror turning ray **d** into ray **d′** has unit normal

```
n = unit(d′ − d)          incidence = acos(−d · n)
```

which is exactly what `periscope.scad` does — it builds `n1`, `n2` from
the traced directions and derives the tilts and incidences from them, so
the two can't drift apart.

### The real constraint: turn angle vs. aperture

A mirror that turns a ray by angle T sits at incidence `i = (180° − T)/2`.
So a *small* turn demands a *grazing* mirror. The two turns must sum to θ,
which means you cannot have both mirrors turning gently — and gentle turns
are precisely the ones that eat the aperture.

Splitting the fold as a zigzag is what makes it work: send the ray steeply
*up* out of mirror 1, then turn it back down to horizontal at mirror 2.
The single knob controlling this is the elevation of the ray between the
mirrors (`mid_elevation` in the model). At θ=60°, with 152mm of usable
mirror:

| ray between mirrors | incidence M1 / M2 | aperture | FOV | M2 sits |
|---|---|---|---|---|
| 20° | 50° / 80° | 26mm | 3.0° | forward, barely up |
| 40° | 40° / 70° | 52mm | 5.9° | mostly forward |
| 60° | 30° / 60° | 76mm | 8.6° | up and forward |
| 75° | 22.5° / 52.5° | 92mm | 10.5° | nearly straight up |
| 90° | 15° / 45° | 107mm | 12.1° | straight up (vertical mast) |

The consequence is unavoidable and worth internalizing before building:
**a corrected-vision periscope has to be tall.** Any attempt to keep it
low and forward drives mirror 2 toward grazing incidence and collapses the
field of view to nothing. The model defaults to 75°.

### What it costs

- **Volume roughly triples.** With the full 160mm stock mirror on the fold
  axis, the seats are ~169mm long, so they need ~195mm of separation not
  to intersect — putting mirror 2 about 190mm above mirror 1 and the whole
  object ~330mm tall above the mount. Setting `fold_axis = "width"` puts
  the 100mm side on the fold instead: ~233mm tall, at reduced aperture.
  That tradeoff is the main thing to decide before printing.
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
