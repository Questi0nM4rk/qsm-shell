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
selector. Coordinated callers are OSD, all rail entries and nested details,
panel/session, ModalHost and notifications. Detached-only motion remains separate;
OSD still uses DataCapsule in fullscreen. Rail retains its source through outgoing
child paint, and matched detail sizes follow the full parent body. Rollout owns
target-size morph; already animated extents opt out. No service policy changes.

The owner accepts the rewritten attached production surfaces' appearance and smooth
motion across the desktop, not only Network. This is visual/motion acceptance;
service, keyboard and input-mask correctness are not inferred from it.
The sound-settings example remains the selected library review item. Production
desktop startup is owner-requested; its imports resolve directly to this shell.
Startup alone is not interaction verification; generic library variants remain
separate from the desktop surfaces the owner reviewed.

## Contract

- **Settings:** required `host`, `rolloutId`, `bodyWidth`, `bodyHeight`; `edges[0]`
  is the reveal axis. `anchorItem`, `placementBounds` and `nudgeToBounds` place the
  free axis; `parentRollout`/`childRollout` describe nesting. Default frame depth
  comes from the host, with `Style.frameThickness` fallback and explicit inset
  overrides. Negative `edgeInset` selects automatic depth; a nonnegative value
  overrides both axes, while explicit `edgeInsetH`/`edgeInsetV` override one.
   `padding` insets the full-size content slot. `deformScale` and `settleContent`
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
owns only these example settings; it connects no desktop service. A compact/wide
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
| structure / interaction | One source, full-size content and host-owned consequences | A generic container must not acquire desktop policy | frame/parent source; shared keep-open | source placement, traversal, dismissal and content actions |
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
