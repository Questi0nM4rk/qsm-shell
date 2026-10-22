# Rollout

An auxiliary container that expands its source's registered silhouette around
full-size content. The source is a frame band or a parent Rollout in the same
`ShellBorder`, not an arbitrary Item. Normative target:
[`rollout-expansion`](../../openspec/changes/rollout-expansion/specs/rollout-expansion/spec.md).

## Contract

- **Settings:** required `host`, `rolloutId`, `bodyWidth`, `bodyHeight`; `edges[0]`
  is the reveal axis, further edges only square corners. `anchorItem`,
  `placementBounds`, `nudgeToBounds` place the free axis; `parentRollout` and
  `childRollout` nest. Frame depth comes from the host (`edgeInset`,
  `edgeInsetH`, `edgeInsetV` override). `padding` insets the content slot,
  `radius` is the free corners' radius (bodies stay concentric when
  `radius - padding` is `Style.radiusBody`). `tier` is `"large"` or `"small"`
  and chooses the Motion pace. `instantReveal` and `instantRetract` take no
  motion in that direction. `fullscreenDetached`, `fullscreenCapsule`,
  `fullscreenRadius`, `settleContent` and `deformScale` belong to the detached
  fullscreen presentation only; attached geometry never travels or deforms.
- **Content:** default slot and `contentItem`. Natural size is `bodyWidth` x
  `bodyHeight`, never derived from clipped children; long content scrolls or
  elides inside the host's composition. The slot is disabled until the aperture
  is 90 % open and again as soon as `shouldBeActive` drops.
- **Open and close:** the host owns `shouldBeActive`; `suppressed` hides at once.
  Reveal and retract are one aperture motion; a turn-back covers only the
  distance left. A source with a still-painted `childRollout` stays revealed
  and reports `animating` until the child hides.
- **Reports, never decides:** `triggered`, `hovered`, `keepOpen` (`hovered` plus
  `closeDelay`), `wantsOpen`, `focusWithin`, `hitActive`, `animating`,
  `viewportRect`, `silhouetteRect`, `settledBodyRect`, `anchorRect`, `nudge`.
  Pointer facts come from the host's `ScenePointer` through `triggerAreas` and
  `hoverAreas` (host coordinates; empty `hoverAreas` means the own silhouette).
  Dismissal and what focus means stay with the surface.
- **Keyboard and screen reader:** no keys, no tab stop; content controls keep
  their own routes and names. The item is an `Accessible.Pane` while it shows;
  the host names it through `Accessible.name`.
- **Motion:** Motion's `revealSmall`/`revealLarge`, `morphGlide` and curves; no
  overshoot. Reduced motion uses their reduced duration.
- **Tokens:** `Style.frameThickness`, `rolloutRadius`, `rolloutPadding`,
  `meltSmoothing`, `Motion.*`. No colour of its own: the silhouette is painted by
  `ShellBorder` (render path in [`12-mechanism`](../12-mechanism.md)).

## Expected

`rollout-hover` opens `workbench/units/Rollout.qml`, the notification-sound
settings on a frame edge. Hover the top band: the surface opens on entry, stays
open on the band, the body and the path between, and closes 180 ms after the
pointer leaves. Toggle Quiet mode by pointer and Space, open the alarm detail
(short and full-span), switch edge, width, content (normal, long, empty),
disabled actions, tier, suppression, and the detached fullscreen form. Content
never moves while the aperture grows.

Not designed: arbitrary shapes, service or compositor policy, a focus-retention
rule, a second expansion type.

## Measured (1.25 scale, 800 x 500 scene, body 316 x 184)

- Content inset 16 px on all four sides; body 316 x 184 and frame depth 12 sit on
  the 4 px grid; the free axis centres on its anchor (offset 0) and lands on a
  half device pixel (302.5), invisible under the soft edge gradient.
- Trigger zone equals the band, 40 x 12 px; the hand reaches the body with a 0 px
  corridor. Open 245 ms, retract starts 233 ms after the pointer leaves (180 ms
  grace), median frame interval 16 ms.
- Contrast on the rendered pixels: heading 13.7:1, label 13.3:1, supporting text
  8.6:1, switch outline 8.6:1 against the band.
- One small-tier reveal writes the host registry 38 times over 16 frames; a
  turn-back from 55 % open retracts in about 100 ms, from 90 % in about 185 ms.
- Keyboard: Tab walks the Hide-alarms button, then the child's switch, in
  visual order; the ring sits outside each control, unclipped, 8.9:1
  against the band, and a click shows none.
