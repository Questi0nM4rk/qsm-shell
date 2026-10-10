## ADDED Requirements

### Requirement: Capsule is a genuine composition container
The shell descriptor/runtime SHALL support mock-screen and data-capsule container
nodes. Capsule child nodes SHALL render in the actual component slot and register
independently with the existing scene/adapter node API. Unsupported node/action/
target names SHALL refuse, never fall back to a root callback.

#### Scenario: Inspect and drive a nested child
- **WHEN** a composition selects or drives the named sound child inside a capsule
- **THEN** the child exposes its own controls, actions and real native Slider target while its parent exposes capsule state

#### Scenario: Refer to a missing child
- **WHEN** a flow addresses a node or native target absent from the composition
- **THEN** it fails naming the missing route rather than operating a sibling or root

### Requirement: Sound fixture composes the actual Slider with truthful local state
The shell sound-channel fixture SHALL reuse the real Slider and hold local level
and mute state separately. Mute SHALL preserve level, level writes SHALL unmute,
and pointer/wheel/key/action routes SHALL report real intents and resulting local
state. The preview SHALL NOT mutate production PipeWire or desktop persistence.

#### Scenario: Repeated mute and level change
- **WHEN** a sound label is clicked twice and then a level is moved by native input
- **THEN** mute/unmute preserve stored level, the level write unmutes, and fresh actual events identify each operation

### Requirement: Composition routes presentation without duplicating timers
The capsule host SHALL own one presentation lifetime and answer real timeout intent.
Sound changed/mute-changed events SHALL route through declared links to the parent
open action, which refreshes budget even when already open. Environment changes
SHALL preserve child state and node identity without reconstructing the tree.

#### Scenario: Another event occurs while already visible
- **WHEN** a second sound operation emits the same supported event with the capsule open
- **THEN** a fresh component/route record reaches the parent and its single timeout budget restarts

#### Scenario: Switch mode with edited sound
- **WHEN** simulated desktop/fullscreen toggles after changing sound level and mute
- **THEN** the mock frame changes while the same capsule/child retain their stored state and usable input routes

### Requirement: Requested composition is discoverable and verified before handoff
`workbench/compositions/capsule-sound.json` SHALL be a validated, discoverable
Compose starter, not a renamed story or separate provider. Existing explicit
composition launch SHALL select it over a blank draft while keeping the catalog
reachable. Handoff SHALL verify shell provider, document, readiness and rendered
canvas before claiming the item is prepared.

#### Scenario: Owner opens the sound Compose example
- **WHEN** capsule-sound is selected through Compose starters or its explicit existing launcher path
- **THEN** the tree includes independently selectable mock screen, capsule and Slider child, not an empty root document

### Requirement: Integration evidence exercises behavior and remains scoped
Targeted base/composition flows SHALL cover native input, node routing and host
outcomes, environment transitions, repeated presentation and reset/cancellation.
They SHALL distinguish simulated environment, native window evidence and owner
acceptance. Existing sound-story flows SHALL migrate to their actual composition
target rather than keeping obsolete assertions or fabricated success.

#### Scenario: Flow proves child-to-parent route
- **WHEN** native Slider input produces a changed event
- **THEN** the flow asserts the child state, fresh component event, named parent route and actual open/timer outcome

#### Scenario: Cancel presentation then reset
- **WHEN** a pending timed composition is closed/reset before expiry
- **THEN** cancelled work cannot later emit completion and the next independent presentation remains functional
