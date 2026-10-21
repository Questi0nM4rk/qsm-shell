## Why

The owner needs to inspect a general floating data container on a desktop-shaped
preview, then compose it with real controls. The current DataCapsule unit embeds
sound policy, and the composition descriptor cannot host DataCapsule children;
opening a workbench process therefore does not deliver the requested proof item.

## What Changes

- Replace the sound-specific DataCapsule unit with a general base story on a
  provider-owned mock screen, with position, footprint, orientation and lifetime controls.
- Consume the workbench's explicit simulated fullscreen environment; keep it
  independent of actual compositor/window fullscreen.
- Add DataCapsule as a genuine composition container whose children occupy its
  real slot and retain independent node identity, actions and native targets.
- Add a discoverable sound composition using the actual Slider, host-owned level
  and mute state, and declared event-to-container routes.
- Migrate the current capsule flows to the correct base/story/composition targets;
  verify outcomes, not a renderer that merely looks like a composition.
- Update the component/provider records before implementation, and dispatch only
  one file-bounded task at a time.

## Capabilities

### New Capabilities

- `mock-screen-preview`: Shell-owned desktop/fullscreen mock composition and placement bounds.
- `data-capsule`: General container contract and a content-neutral base story.
- `capsule-compositions`: Real child-slot composition, sound fixture and routed integration evidence.

### Modified Capabilities

None. This repository has no existing durable OpenSpec specifications. Existing
code is investigated and reused, not presumed to satisfy these new requirements.

## Impact

Library component `qml/QsmShell/Components/DataCapsule.qml`, its existing
Style/Motion/token dependencies, shell `workbench/` adapter, unit, descriptor,
composition renderer, fixtures, JSON examples and targeted flows. No new provider:
the product providers remain this library and its consumers.

Dependency: `../qsm-workbench/openspec/changes/fullscreen-preview-environment/`
owns the generic environment contract and flow step. Shell tasks cannot silently
implement that contract in the provider or edit workbench-owned window code.

Non-goals: production OSD/notification service integration, notification repairs,
CPU/memory compositions, new rollout mechanics, public packaging, or claiming
that a mock screen proves an overlay above a separate fullscreen client.

## Critiques

- **Devils-advocate — task boundary ambiguity:** corrected overlapping readonly/
  forbidden prefixes and included CompositionNode context forwarding in SH-C1's
  write boundary. Writes remain exclusive-only. The claim that SH-C1 must edit
  workbench QML is rejected: its verified dependency and published spec define
  the interface; the shell consumes it without owning the harness model.
- **Future-archaeologist — contract durability:** the reviewer found the context
  and DataCapsule APIs understandable. Main-agent follow-up made the owner review
  pause and uncommitted task status explicit so future dispatchers cannot infer
  acceptance or fabricate completion from a green flow.
- **Scope-sniper — read-only references versus service integration:** SH-C5 now
  explicitly uses desktop source only as an appearance/semantics reference. No
  production service calls or writes are permitted; removing that reference would
  defeat the owner's requested desktop sound match. The neutral base must be
  owner-accepted before container/sound Compose implementation proceeds, and SH-C7
  hands over only that subsequent composition.

Read-only Nemotron critique plus main-agent contract follow-up completed; findings
are corrected or explicitly rejected above. Strict change validation passes;
that is an artifact gate, not component acceptance.
