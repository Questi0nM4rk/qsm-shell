# ShellBorder

The edge-melt shell frame; it registers rollout regions, bulges and fullscreen capsules and renders the welded seam, and surfaces own every behaviour behind it.
states: none; slots fill up to eight bulges and eight fullscreen capsules with rect, radii, deform and blend parameters each.
actions: register and unregister rollout regions, bulges and fullscreen capsules; snap, weld and seam-overlap geometry helpers; no user-facing route. Fullscreen registrations remain available as input holes; `paint: false` excludes a registration from shader paint while leaving it eligible for the consumer's input mask.
pointer: none; it takes no pointer itself and reads regions only through the host pointer map.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; it is chrome, not content.
size: edge thickness and viewport radius from the frame scale; regions arrive in host coordinates and slots quantize them for the shader.
tokens: frameThickness, radius2xl, meltSmoothing, band fill, edgeColor, edgeStrength, edgeFade and the edge shader; no local colours or measurements.
motion: none; it renders host-animated geometry. Origin sides extend fill through the weld; child-facing seam continuations are paint-only.
registration: snapping skips declared source-origin sides; other nearby edges still snap and cap their welds. Attached expansion supplies a growing aperture with identity deformation. Paint-only normalization does not change content size or viewport input.
paint endpoint: slot outness restores the incoming fill field; the edge gate (water law) applies outside the incoming union. Removing a hidden slot must not change frame lighting.
not designed: pointer tracking, rollout behaviour or surface content; use ScenePointer, Rollout or the host for those.

## UIX audit

Evidence: source-reviewed only. No runtime-exercised or owner-accepted evidence is claimed. Accessibility criteria are a11y-audit's; the lines below state facts, not verdicts.

### Purpose and consequence

The frame paints one merged silhouette (the band plus every open rollout) and publishes the rects a consumer masks input with. A person meets it as the shell's edge: when it is right, an open panel reads as one body with the frame; when a registration is wrong, the panel looks cut off or pinched where it meets the edge.

### Controls, states and routes

- Props and functions: `entryFilter`, `pointer`, `fullscreen`, `leftEdge`, `edge`, `band`, `edgeColor`, `edgeStrength`, `edgeFade`, `handle0`, and the register and unregister functions for rollout regions, bulges and fullscreen capsules (ShellBorder.qml:26-353). All are implemented.
- Unit controls (`workbench/units/ShellBorder.qml:63-86`): mode (shown, hidden, suppressed), state (windowed, fullscreen), form (attached, detached), hit (registered, withheld), policy (all, filtered). Each option sets a property that exists and reaches the shader through Rollout. Unit actions `add-capsule` and `remove-capsule` call implemented registry functions.
- Own states: none. Capacity: 0 to 8 bulges and 0 to 8 fullscreen capsules (ShellBorder.qml:76, 98).
- Pointer: none. `pointer` (ShellBorder.qml:34) is a pass-through for Rollout's `keepOpen`; the unit leaves it null, so no hover behaviour is exercised here.
- Keyboard, wheel, focus: none. The type is never a tab stop and has no input handlers. Its content's routes belong to Rollout and the consumer.
- Screen reader: none of its own. a11y-audit owns that method for the surface.

### Sizes, empty, long, failure and cancellation

- Sizes come from Style: frame thickness 12 (tokens/deep-night.json), viewport radius `radius2xl` 28, melt reach `meltSmoothing` 20 (:127), snap reach `edgeSnapReach` 32 (:128), seam overlap 8 (:136), edge fade 16 (:137). The type holds no measurement of its own.
- Empty: with no registrations only the band is painted. A zero-size slot is skipped (edgemelt.frag:171-172).
- Long: a ninth bulge or capsule is accepted and not painted (see proposals).
- Failure: registration does not validate rects or radii, and nothing reports a rejected entry.
- Cancellation: unregistering an absent id is a no-op (ShellBorder.qml:108-114, 304-311). Rollout's `suppressed` unregisters at once (Rollout.qml:535-545 and the destruction handler at 584-589).

### Visual roles and palette pairs

Source values: band `#271e30`, surface `#3b3145`, overlay `#4c4357`, text `#f0ecf5` (tokens/deep-night.json:3-7), edge colour `#5e357f` (Style.qml:92 via Tokens.qml:20) at edgeStrength 0.5 over edgeFade 16 px. Ratios are computed from these hex values with the WCAG 2.2 relative-luminance formula, not rendered:

| pair | ratio | note |
| --- | --- | --- |
| band vs surface | 1.30:1 | layer separation; the ladder's step |
| band vs overlay | 1.71:1 | layer separation |
| edge pixel (50 % edge colour over band, `#432a58`) vs band | 1.30:1 | decorative separation line; it carries no information, so 1.4.11 does not apply |
| text vs surface | 10.53:1 | the unit's Card text; 1.4.3 passes |

Roles used: band (the silhouette fill), edge separation (the line at the silhouette edge). No role is taken from `Tokens` directly.

### Motion and reduced motion

None in this type: ShellBorder.qml has no animation. The geometry it draws is animated by Rollout (`offsetScale`, `revealAnim`, `Behavior on bodyHeight`), and the hover keep-open delay is `hoverGrace` 180 (tokens/deep-night.json:75). The reduced-motion form is Rollout's and was not examined here.

### Pointer geometry

- Input shape: ShellBorder publishes no pointer target. Its input is `maskRects` (ShellBorder.qml:45-47): the Rollout viewport rects, registered only while `hitActive` (Rollout.qml:399, 542). The painted silhouette is the body rect passed to `registerBulge` (Rollout.qml:529).
- Trigger in the unit: the band item, 16 by 12 px (`Style.space4` by `Style.frameThickness`), top centre. Width model: one-dimensional, Shannon form, ID = log2(1 + D / W), W = target extent along the approach axis, D = centre to centre. Assumptions: D = 400 px (a pointer from the centre of an 800 px viewport; no pointer source exists to measure it), label origin at the band centre, equal weights.
  - W = 12 px, horizontal approach: ID = log2(34.3) = 5.10 bits; landing tolerance +/- 6 px.
  - W = 24 px (the pointer floor in ux-audit check 3): ID = log2(17.7) = 4.14 bits; tolerance +/- 12 px.
  - Vertical approach from below the top edge: the screen edge stops the pointer, so the approach has no far boundary and the model gives no ID.
- Neighbouring interference: none in the unit. A host's trigger neighbours are the host's and were not read.
- Trigger-to-panel corridor and timing: owned by Rollout (keep-open union, `hoverGrace` 180). Not measured in this record.

### Findings

Source-backed defects:

- SB-1, minor, shared. `workbench/stories.json:969`: the description says "Full-viewport shell border", but the unit declares 380 by 380 implicit size (unit lines 19-20) and the story viewport is 800 by 500 (stories.json:964-967). What a person sees: a square frame in the window, not a full-viewport border. Unless the workbench stretches the unit, which the source does not show.

Proposals (taste and shape, no defect a person sees):

- Fail loud at the ninth registration. `registerBulge` (ShellBorder.qml:284-302) accepts a ninth id, `occupied` clamps to 8 (ShellBorder.qml:402), and the ninth is never painted. The 8-slot budget is documented as never exceeded (docs/12-mechanism.md:232-233), so this is a latent failure, not an observed one. Propose a typed error with a code at the cap.
- The `?fullscreen=` query on the shader URL (ShellBorder.qml:394-395) names no variant: the shader has one program and a `fullscreenMode` uniform (edgemelt.frag:144, 409 in ShellBorder.qml). The comment's reason (a binary cached across hot reload) cites no source. Either record the reason with its source or remove the query.
- Edge doubling: a Card inside a Rollout draws its own cardglow edge (Card.qml:46-58) inside the silhouette's edge line, so the rail shows two edge lines about 16 px apart. Card.qml:11-14 says a card sitting flat inside another body turns it off. Propose `glow: false` for a card in a rollout, after an owner look.
- The trigger band is 12 px along x, below the 24 px pointer floor. Whether the consumer's hover zone is larger is not visible from this type. Propose the consumer publish its trigger zone next to the rollout, not a second hit model here.

Hypotheses (unmeasured):

- Removing a middle slot re-packs the remaining bulges (`Object.keys` order, ShellBorder.qml:45-47, 73-75), and the shader folds slots in order (edgemelt.frag:159-238), so a neighbour's melt could shift by a small amount. Suspected, not measured.
- The edge line draws along the viewport's inner face as well as around bodies (the frame's zero contour, edgemelt.frag:134-144). This may be intended; not judged.

Comparison: no caelestia sibling implements an edge-melt silhouette. A grep of `~/Clonned/caelestia/repo/components/controls/` for border or melt matched only StyledRadioButton.qml, which is not a sibling. Nothing was compared.

Not examined: live window, capture, geometry dump, fullscreen in a live window, multiple outputs, 200 percent scale, light and high-contrast themes (tokens are deep-night only), the eight-slot stress case, decompilation of `edgemelt.frag.qsb` against the current source (git shows the binary last changed in the same commit as the source; the binary content was not checked), reduced motion, and every accessibility criterion (a11y-audit).
