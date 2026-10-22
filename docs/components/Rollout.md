# Rollout

An auxiliary container that expands its source's registered silhouette around
full-size content. The source is a frame band or a parent Rollout in the same
`ShellBorder`, not an arbitrary QML Item.

## Target and current implementation

The target is [`rollout-expansion`](../../openspec/changes/rollout-expansion/specs/rollout-expansion/spec.md).
Shared source now provides bounded aperture progress, readonly `contentItem`,
`settledBodyRect`, automatic expansion frame insets and host-to-parent placement.
Attached expansion pins deformation and content scale to identity; close removes
normal input immediately and suppression ends pending motion/grace. Registries
follow contour, radius, weld and transform changes, not just item dimensions.
The shader and its compiled artifact are unchanged.

Source implementation: expansion is the only attached geometry, with no `borderExtrusion`
selector. Detached-only motion remains separate. A rollout retains its source through
outgoing child paint, and matched detail sizes follow the full parent body. Rollout
owns target-size morph; already animated extents opt out. No service policy changes.

Appearance and smooth motion of the attached surfaces are accepted; service,
keyboard and input-mask correctness are not inferred from that. The sound-settings
example remains the selected library review item. Startup alone is not interaction
verification.

## Contract

- **Settings:** required `host`, `rolloutId`, `bodyWidth`, `bodyHeight`; `edges[0]`
  is the reveal axis. `anchorItem`, `placementBounds` and `nudgeToBounds` place the
  free axis; `parentRollout`/`childRollout` describe nesting. Default frame depth
  comes from the host, with `Style.frameThickness` fallback and explicit inset
  overrides. Negative `edgeInset` selects automatic depth; a nonnegative value
  overrides both axes, while explicit `edgeInsetH`/`edgeInsetV` override one.
   `padding` insets the full-size content slot. `radius` is the free corners' radius (default `Style.rolloutRadius`); a compact rollout may take a smaller one, and its bodies stay concentric when `radius` minus `padding` equals `Style.radiusBody`. `deformScale` and `settleContent`
   apply only to detached fullscreen compatibility, never attached geometry.
- **Content:** default slot plus readonly `contentItem` access. Full body size
  never derives from clipped children. Content is stationary relative to its
  source during reveal; host-requested size/placement changes can still move it.
  Long content scrolls or elides inside the host's chosen full-size composition.
- **Open/state:** host owns `shouldBeActive`; `suppressed` snaps hidden. Shared
  progress supports hidden, revealing, shown, retracting and reversed motion.
  Fullscreen capsules are a separate presentation, not an invisible frame source.
- **Pointer:** `ScenePointer` on the common ancestor reads host-coordinate
  `triggerAreas` and `hoverAreas`. Rollout owns containment, descendant retention
  and one grace timer; reports `triggered`, `hovered`, `keepOpen`, `wantsOpen`.
  It never dismisses itself or recreates a host's service policy.
- **Keyboard/wheel/focus/accessibility:** no generic key or wheel interception,
  tab stop, focus policy or screen-reader role. Content controls retain their
  native routes and names. Focus alone does not imply generic retention.
- **Actions:** no user-facing actions of its own. Opening/closing is host-owned
  intent; content actions keep their owning component's shared functions.
- **Geometry:** aperture grows from the source along one axis; extra contacts
  square corners, not add another axis. Paint receives the aperture, free radii
  follow its current half extents, and content/shader deformation is identity.
  Nested origins use settled full-body source extents in host coordinates.
  An anchored card is centred on its anchor along the free axis, shifted by
  exactly the overflow when it would cross `placementBounds`. The half-height
  it centres with is held once the reveal is near-settled, so a list that grows
  keeps its top; a new anchor re-centres through its size morph.
  Anchored placement uses a visual `ShellBorder` host: Qt's `mapFromItem` takes
  an `Item`, not a `QtObject` with a lookalike mapping function. Keep the host,
  anchor and QML parent coordinate spaces distinct in fixtures as in consumers.
- **Input/lifetime:** expose `viewportRect`, `silhouetteRect`, `hitActive` and
  `animating`; normal hit registration uses only the near-settled aperture and
   withdraws on close/suppression. The content slot disables on close/suppression;
   hosts retaining a source for its child also disable their retired actions.
   Retention for a still-painted `childRollout` belongs here, not inside the
   host's `shouldBeActive`: a retained source stays revealed, keeps its own
   input and content withdrawn, and reports `animating` until that child hides.
  outgoing content identity and dimensions survive until hidden. Modal catch
  regions remain host policy through `registerHitRect: false`.
- **Motion/sizing:** existing small/large Motion curves, no overshoot, independent
  fade, scale or attached goo. Reduced motion uses the existing reduced duration.
  `animateBodySize` chooses one target-size animation or direct animated child
  extents; reveal progress never changes preferred size.
- **Tokens:** `Style.frameThickness`, `rolloutRadius`, `meltSmoothing`, spacing and
  existing `Motion` tiers. No new tokens, palettes or per-surface timing copies.

## Design record

Current review task: temporarily mute notification sounds, see the immediate
on/off verdict, and optionally keep alarms audible in a nested detail. The unit
owns only these example settings; it connects no service. A compact/wide
composition changes requested width, never text size or reveal scaling. Empty
and long copy elides inside the same slot. Content actions disable during close;
native Switch pointer, Space/Return, focus and accessible names remain intact.
The host keeps the source until its outgoing detail is hidden and disables the
source's retired actions while it remains painted. Detail extents follow the
source's morph directly. Programmatic routes use a name-to-function dictionary;
the declared action list comes from its keys and unavailable actions return false.

Reference comparison: Caelestia `modules/osd/Wrapper.qml` and
`modules/bar/popouts/ClipWrapper.qml` retain full-size content behind a clip;
`modules/drawers/ContentWindow.qml` and `plugin/src/Caelestia/Blobs/shaders/blob.frag`
merge registered shapes. Keep clip/content separation and circular unions, not
their travelling offsets, opacity, service timers, deformation or border sinks.
Radix Popover's custom anchor and portalled content separate placement from
clipping ancestry; keep that distinction, not its managed focus/dismissal.
Those separations are common patterns; stationary expanding contours are the
owner's accepted choice. The blueprint's semantic tokens, 4px rhythm and
purposeful motion govern the example; existing tokens suffice.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture / task | An auxiliary shell surface exposes a task and returns attention to the application | Owner selected the OSD's quieter growing contour | host intent; Rollout | one live owner-selected task |
| structure / interaction | One source, full-size content and host-owned consequences | A generic container must not acquire consumer policy | frame/parent source; shared keep-open | source placement, traversal, dismissal and content actions |
| hierarchy / system | Source and expansion are one fill; no Card backdrop or independent rim | A travelling panel reads as another object | ShellBorder merged SDF | contour and stationary-content comparison |
| responsive | One reveal axis on all sides, settled source extent for nesting | Animated apertures must not become another item's origin | host coordinates; anchor/nudge | selected edge, source resize and nested seam review |
| states / access | Native content states remain; retired input withdraws before paint | A disappearing picture is not still an action target | near-settled input; retained identity | focus, disable/close, interruption and reset |
| polish | Current aperture radii, identity deformation and neutral terminal slot | Removing a hidden expansion must not restore the source twice | shared Motion; normative outness | closing through its settled tail |

Render path: host intent → progress → parked full-size content / growing clip →
host-coordinate contour → registration normalization and weld masks → shader
union/fill/stroke → separate input aperture → hidden-neutral unregister/unload.
At zero outness the incoming fill/rim fields, stroke gate and lighting are
unchanged before removal. See [`12-mechanism`](../12-mechanism.md).

Expected: `rollout-hover` in the catalog opens `workbench/units/Rollout.qml` as
**Rollout / Notification sounds**, initially a top-attached sound preference.
Toggle Quiet mode, close/reopen and reverse the contour without moving content.
Other edges, hover/grace, short/full-span alarm details, compact/wide target sizes,
long/empty content, disabled actions, motion tiers and suppression are reachable.
Fullscreen/detached controls retain the separate presentation, not proof of capsule
acceptance. The owner judges one selected item; no automatic checks or self-acceptance.

Not designed: arbitrary shapes, service/compositor policy, new focus/dismissal
rules or a second expansion type. No new visual design is commissioned: task,
hierarchy, tokens and states stay as recorded; this rewrite consolidates their
mechanism. Archived travelling records are not active instructions.

## UIX audit

Evidence: source-reviewed only. Runtime-exercised: none. Owner-accepted: none. No Workbench session,
capture or live tree was used, so channels 1 and 2 of `ui-audit` were not available. Every number
below comes from `Rollout.qml`, the consumer code it names, `Style/Tokens.qml` and `Style/Motion.qml`.
Pixel claims are hypotheses. Criteria for focus, names and reduced motion belong to `a11y-audit`,
which must run on this surface; `ux-audit` check 7 and `review-animations` own the motion verdicts.

### Purpose and consequence

The task is to let a shell surface grow out of its source edge and return into it, with its content
standing still. The consequence for a person is that the surface arrives from the frame they already
look at and leaves the same way. The host owns intent; Rollout reports `triggered`, `hovered`,
`keepOpen` and `wantsOpen` and never closes itself (`Rollout.qml` 120-125, 133).

### Controls, states and routes

| Item | Expected (this record) | Implemented (source) |
| --- | --- | --- |
| `shouldBeActive` | host intent, the one input | 37, 343 |
| `suppressed` | snaps hidden, no retract | 39, 147-154, 348-349 |
| `instantReveal`, `instantRetract` | the aperture jumps to its target in that direction (a key-opened surface) | `_moveOffset` |
| `edges` | `edges[0]` is the reveal axis, others flush | 18, 324-325; validated once, at completion (598-607) |
| `anchorItem`, `placementBounds`, `nudgeToBounds` | free-axis placement | 22-27, 172-245 |
| `parentRollout`, `childRollout` | nesting, squared corners | 31-32, 114-116, 261-276, 341-343 |
| `hoverAreas`, `triggerAreas`, `closeDelay` | keep-open and open regions | 81-113, 85 |
| `tier` | reveal 250 ms small, 500 ms large; retract 200 and 400 | 42, `_moveOffset` |
| `registerHitRect` | modal catch regions opt out | 46, 399 |
| `padding` | inset of the full-size slot | 54, 636-639 |
| `fullscreenDetached`, `fullscreenCapsule`, `fullscreenRadius` | detached capsule only | 59-62, 290, 331-332, 532-536 |
| `fullscreenInset` | declared, no reader found | 61 only; no reader in this file or the consumers read |
| `settleContent`, `deformScale` | detached compatibility only | 64-65, 423-427, 641-648 |
| `animateBodySize` | one morph or direct child extents | 67, 381, 390 |
| `contentItem`, default slot | full-size content | 10, 620-635 |
| `actions` | none (host-owned intent) | none declared |

States: hidden, revealing, shown, retracting, retained for a child (`_sourceRetained`, 341-343),
suppressed (snap) and fullscreen-detached. None has been exercised.

Routes, as the source gives them:

- Pointer: no handler of its own. It reads `host.pointer` (98) and the host's `ScenePointer` decides
  containment. Entry is immediate (`triggered`, 99-101). Exit is `keepOpen` through a 180 ms timer
  (`closeDelayTimer` 135-138, `onHoveredChanged` 161-166).
- Keyboard and wheel: none in this file. Content keeps its own routes.
- Focus: none. Content is disabled until `_inputReady` (`shouldBeActive` and `revealProgress >= 0.9`, 642).
- Accessibility: no role or name in this file. The example's Switch names itself.

### Sizes, empty and long content, failure, cancellation

- Example compact body: 316 x 184 px (`controlWidth` 380 minus 2 x `space6` 32; height is
  3 x Control `md` 40 plus 2 x 32). Wide body: 380 x 184 (unit 70-71). Child sizes are the
  unit's arithmetic, not Rollout's.
- Long content does not grow the component: implicit size is body times progress (329-330) and
  `clip: true` (333) cuts it. Scrolling or eliding is the content's job. The unit's long copy wraps
  inside its own `Prose` (unit 88-90) and is not measured.
- Empty: Rollout has no empty state. The example hides its column and shows its own text (unit 76, 123-129).
- Failure: zero body size yields zero size, silently. Invalid `edges` logs once at creation (606).
- Cancellation: `suppressed` completes running animations (147-154). Reversal mid-motion retargets
  from the current value over the full tier duration (360-372, see P6).

### Visual roles, palette, motion

- Rollout paints nothing. The silhouette is the `ShellBorder` shader, fed by `registerBulge`
  (529-531). Radius is `min(rolloutRadius` 28, half the aperture) on free corners and 0 on attached
  edges (258-260, 281-285); the radius shrinks with the aperture by design (254-256).
- Palette pairs: none in this file. The example's root uses `Style.band` (unit 31). Pairs for
  its content belong to Prose and Switch.
- Motion: reveal 250 ms (small) or 500 ms (large), curve `[0.05, 0.7, 0.1, 1.0]`; retract 200 or
  400 ms (`Motion.exit`), curve `[0.3, 0, 0.2, 1]` (Motion.qml 94, 98); morph 250 ms, `OutQuart` (Motion.qml). Goo and deform run
  only detached (423-427, `_joined` 290).
- Reduced motion: reveal and morph become 120 ms (Motion.qml 72-73, 77). The hover grace does not
  change (Motion.qml 117, Tokens.qml 68). The rule behind this is in conflict, see C1.

### Pointer geometry

Assumptions, labelled: output 1920 x 1080 logical px at scale 1; pointer origin at the screen centre
(960, 540), a modelled start, not a measured or averaged human path; approach straight to the top edge.
Width model: one dimension, W = the trigger's depth along the approach normal. The 40 px cross width
is outside the ID.

Measured from tokens and code:

- Trigger input: the band item, 40 x 12 px (unit 47-53, 67; `ShellBorder.edge` defaults to
  `frameThickness` 12). Rollout does not paint it.
- Painted body when open: 316 x 184 px, centred on the trigger (placement 215-245, nudge 231).
- Keep-open region with empty `hoverAreas`: trigger union viewport (110-113). It equals the painted
  silhouette: no halo.
- Corridor from trigger to panel: trigger bottom at y = 12, body top at `edgeInsetV` = 12
  (52-53): gap 0 px, length 0 px.
- Timing: open on entry at 0 ms; reveal 250 ms; close 180 ms after the pointer leaves the union
  (Tokens.qml 68).
- Fitts, strict model: D = 532 px (origin to trigger centre), W = 12 px, so
  ID = log2(1 + 532 / 12) = log2(45.33) = 5.50 bits.
- Edge overshoot: the pointer stops at the screen edge, so the far side of W is unbounded. The
  5.50 bits is an upper bound, not a time. Aim tolerance across the 40 px width is +/-20 px and
  is not in the ID.
- Landing tolerance: 12 px depth, 40 px width, zero halo, then 180 ms of grace.
- Child (alarms): no pointer trigger. It opens by click on the "Alarm settings" Capsule (unit 109-120),
  so its geometry belongs to Capsule's record. Not examined here.

### Findings

Defects (source-backed):

- **D1.** `Rollout.qml` 508-545 and 584-590: `syncRegistries` and
  `onDestruction` address only the current `host` and `rolloutId`. No handler covers a change of
  either (547-561). A person sees a stale silhouette bump painted on the old frame and an input
  region still registered on the old host after a host or key change on a living instance. Severity
  minor: the sites read (unit 56-58) do not change host or key.
  Fix: remember the last host and id, unregister them before registering when either changes, and
  do the same in `onDestruction`. Shared: no.

Redesign proposals (owner or review decisions, not defects):

- **P1, keep-open halo.** The default keep-open region is the painted silhouette (110-113), so the
  180 ms grace is the only forgiveness. A pointer that slips 1 px off the body and returns after
  181 ms closes it. Owner: a default inset corridor, or require `hoverAreas` from consumers.
- **P2, trigger depth.** The example trigger is 40 x 12 px, below the 24 px pointer floor
  on the depth axis; the screen edge is the only mitigation, unmeasured. Consumer decision: extend
  the trigger into the band, or add a trigger inset property.
- **P3, dead guard.** `onPointerChanged` (156-159) runs when the `pointer` reference changes, not
  when `pointer.inside` changes, so its stop never runs in normal use. Delete it, or move the stop to
  the inside signal and decide whether leaving the scene closes at once. Today the 180 ms grace runs
  through `onHoveredChanged`.
- **P4, unused property.** `fullscreenInset` (61) has no reader found. Delete it.
- **P5, edges.** `edges` is validated once (598-607), so a runtime change is silent. Validate on
  change, or document it as creation-time only.
- **P6, interruption.** `_moveOffset` restarts from the current value over the full tier duration,
  so a reversal at 90% takes the whole 250 or 500 ms (200 or 400 on the way out). For
  `review-animations` (standard 6).

Source conflicts (the owner rules):

- **C1, reduced motion.** AGENTS.md law: "A one-shot position animation is REMOVED under reduced
  motion, not shortened, and never runs during a gesture." The reveal and morph are one-shot size and
  position changes, and Motion.qml 72-73 and 77 shorten them to 120 ms. This record's contract says
  "Reduced motion uses the existing reduced duration." Shared: yes (Style/Motion.qml).
- **C2, retract curve.** Motion.qml 96-98 says retract is deliberately not an exit curve: the border
  returns to rest. `review-animations` standard 3 wants exits on ease-out. Shared: yes (Style/Motion.qml).

Hypotheses (unmeasured):

- **H1, binding loop.** In the example, `rollout.shouldBeActive` reads `childPanel.visible` (unit 64),
  `childPanel.shouldBeActive` reads `rollout.revealProgress` (unit 141), `revealProgress` reads
  `offsetScale`, and `offsetScale` reads `_sourceRetained`, which reads
  `childRollout.visible` (342). The cycle is in the dependency graph while nested and open. Qt may log
  "Binding loop detected". Not runtime-exercised.
- **H2, focus on close.** `inner.enabled` goes false (640) when `shouldBeActive` goes false, which
  removes focus from a focused control inside during the retract. Where focus goes is not defined in
  this file. Criteria are `a11y-audit`'s.
- **H3, morph cost.** `Behavior` on `bodyWidth` and `bodyHeight` (381-396) relayouts the slot on each
  frame of the 250 ms morph. Not measured.
- **H4, Fitts model.** If the one-sided edge model is wrong, the 5.50-bit figure is wrong. Only a
  measured run settles it.

Not examined: runtime and capture (no Workbench session, per instruction); live geometry; the
trigger geometry of a host; Capsule and Switch targets; the
wheel routes of content; focus rings; palette pairs; reduced motion at runtime; 2x text scale.
Fullscreen capsules (`ShellBorder` 102-127) were read as source only.
