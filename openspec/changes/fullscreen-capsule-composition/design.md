## Context

DataCapsule already exists as a T.Control with an arbitrary content slot,
host-owned shown state, fade, lifetime intent and Style-based material/elevation.
Its current unit is sound-specific. The shell composition descriptor/node renderer
has no capsule container, so the requested general base and real Compose are absent.

The sibling workbench change `fullscreen-preview-environment` supplies simulated
application state independently from actual window fullscreen. The owner accepted
the original component set, not this new item; prior tests are not acceptance.

## Goals / Non-Goals

**Goals:** a content-neutral base on a visible mock screen, one placement rule,
a true capsule child-slot composition, real Slider sound semantics and honest
node/route/input evidence. Preserve the accepted Quiet Luminous vocabulary.

**Non-Goals:** production service wiring or rollout/capsule swapping, a new
provider, a second Slider implementation, desktop policy in library components,
or automatic review of the rest of the catalog.

## Decisions

### Provider fixture owns the mock screen and placement

Add a shared `workbench/fixtures/MockScreen.qml`, used by the DataCapsule unit and
the composition renderer's `mock-screen` node. This is a provider fixture, not a
new library component. It consumes `previewEnvironment` read-only. Without an
injected context, standalone usage is explicitly desktop simulation using its own
bounds; it cannot claim harness environment support.

The fixture has a neutral mock application underneath an overlay slot. In desktop
mode it shows the real ShellBorder with an application rectangle inset by the
existing frame token on all sides; it does not reproduce production rail services.
In simulated fullscreen the application uses screenRect and the frame is hidden.
The overlay slot and capsule identity are unchanged between modes. A clear fixture
label distinguishes simulation from a real compositor client.

One fixture helper computes a placed body rect from preferred dimensions, `edge`,
`alignment` and `inset`. The four edges and `start/center/end` positions use screenRect
in both modes, never workbench chrome. On left/right the alignment runs top-to-bottom;
on top/bottom it runs left-to-right. Clamp actual body dimensions/position to the
inset screen bounds, keep preferred dimensions unchanged, and report `constrained`
when they cannot fit. Insets are non-negative; excessive inset yields a truthful
empty placement and no interactive target. Shadows do not enlarge the input rect.
Alternative rejected: each unit/node redoing edge geometry or the library knowing
what a screen/frame/fullscreen window is.

### General library container and neutral base story

Keep DataCapsule's API: `shown`, `timeout`, `hoverStay`, `interactive`, `actionLabel`,
`accessibleName`, `size`, `orientation`, `bodySize`, `preferredLength`, `radius`,
`surfaceColor`, `elevated`, its slot, and public actions/facts. Placement belongs to
the fixture/host, not a screen enum in the library component.

`workbench/units/DataCapsule.qml` becomes the one general proof unit. Its slot holds
neutral short/long/empty content, not audio behavior. Controls expose four edges,
three alignments, inset presets, orientation, theme sizes, short/default/long length,
visibility, persistent/timed lifetime, hover retention, elevation, report-only and
disabled cases. Use Style/Motion; no new decorative frame or permanent dashboard.
Base activation records intent and a local host outcome without opening production
services. Programmatic, pointer, keyboard and accessibility routes share activate().

Keep the existing surface default `Style.bandFill`, radius and tokenized shadow;
reduced effects removes elevation and reduced motion affects fades, not timeout
budget. Empty content is legitimate; long content elides/scrolls within its slot.
Small capsules do not promise every possible infoblock is usable inside them.

### Adapter boundary

The shell Adapter opts in with `previewEnvironment`, forwards it to supported
units and CompositionScene, and exposes a public semantic snapshot of the current
environment. Scene forwards the same context to nodes and the MockScreen fixture.
No shell-owned copy of the harness flow engine, environment model or window toggle.

### Real composition with independent identities

Extend `composition-types.json` with provider types `mock-screen` and `data-capsule`.
Both accept child nodes. The mock-screen root fills its declared logical viewport;
capsule nodes own their shown state, timer handling and placement settings. Children
are rendered inside the REAL DataCapsule slot, not beside/over a drawing of it.

Container vocabulary:

| Props | Values |
| --- | --- |
| `open`, `hover-stay`, `interactive`, `elevated` | boolean |
| `timeout` | non-negative milliseconds; zero is persistent |
| `edge` | left/right/top/bottom |
| `alignment` | start/center/end |
| `inset` | descriptor's spacing preset |
| `orientation` | horizontal/vertical |
| `size` | sm/md/lg |
| `length` | short/default/long preset |

Actions are `open`, `close`, `restart`, `cancel-timeout`, `activate`. `restart`
refreshes budget only; `open` requests shown state and restarts even when already
open. Events observe real component `activated`/`timeout-requested` signals;
setup/control mutations are not component events. Public observables include
`open`, `present`, `keep-open`, `accepts-input`, `fullscreen`, `edge`, `alignment`,
`constrained` and an actual `remaining-time` query. Unknown nodes/routes refuse.

The initial capsule child is a provider-owned `sound-channel` leaf fixture based
on the existing real Slider, reused rather than embedding a second implementation
in the base story. Node actions/targets, level and mute state belong to that leaf.
Level is 0..100; mute toggles without changing level; a level write unmutes, matching
AudioService. Desktop-like glyph, inset track, reading in thumb and wheel behavior
use Style and caller configuration. Pure control functions do not invoke PipeWire.

`capsule-sound.json` has a mock-screen root, a named capsule and named sound child.
Child `changed` and `mute-changed` events route to the capsule's `open` action,
which both reveals and refreshes its presentation. Native target for the child
resolves the actual Slider/label, not a nominal root Item. Node selection/inspection
can independently address container and child. Shared identities survive environment
changes; mode is not an instruction to reconstruct a composition tree.

### Verification, migration and handoff

Split base and composition flows rather than cramming unrelated cases into the
64-step document limit. Migrate earlier sound-specific flows to the new composition;
the base story's flows verify only the general container. Tests exercise actual
input, events, routes, host consequences, timeout/reset and mode-change cancellation.
Never assert source shape or copy the component's state machine into JavaScript.

The shell provider's existing Compose starters automatically discover
`workbench/compositions/capsule-sound.json`. Launching with the existing explicit
`--compose` path avoids a restored blank draft; the full catalog stays reachable.
Live handoff on workspace 10 verifies provider, document/key, ready state and native
canvas before reporting prepared. Stop driving input during owner review.

## Risks / Trade-offs

- [Dynamic children are not registered in the slot] → node-addressed route/input flow and independent inspection.
- [Content swap loses level or focus] → stable fixture/tree identity and environment-transition flow.
- [Body activation steals slider/label input] → nested action vs container action tests.
- [A timer expires after reset/close] → cancellation tests against the real container and reconstructed provider.
- [Small sound fixture clips geometry] → use slot/caller geometry without an implicit-size binding loop; do not declare every content valid at every size.
- [Mock is confused with a real overlay] → explicit simulated context and evidence labels; native overlay proof is deferred.
- [Placement is copied] → both base and compose use the shared fixture helper.

## Migration Plan

Update expected/provider docs first. Implement SH-C1 through SH-C7 as bounded
sequential tasks after their declared dependencies. Preserve the library API and
existing unrelated examples. Migrate only DataCapsule-related flows, retaining
their intent and distinguishing historical results from current checks. A defect
in a library component pauses the fixture task for a separate owning-code fix.
Do not remove user drafts, accepted components, worktrees or unrelated changes.

Base review is a hard pause: SH-C3 and WB-E6 prepare the neutral story, and the
owner accepts that named item before SH-C4 starts. SH-C7 prepares only the sound
Compose afterward and waits for its separate judgement.

Owner-feedback correction: the base content works but its control grouping is
rejected. SH-C8 changes only unit control declarations and matching base-flow names:
separate edge, alignment, inset, orientation, size, length, content, lifetime,
retention, elevation and availability; presentation commands have their own group.
It does not change capsule behavior/content. Generic stable renderer geometry is
owned by workbench WB-E7; the harness must not infer these semantic axes. Base
acceptance stays pending until the corrected controls are reviewed.

## Open Questions

None blocking this mock/base/composition contract. Production fullscreen overlays
and notification lifetime repairs require a later separately scoped desktop change.
