## ADDED Requirements

### Requirement: Actionable labels share one guarded operation
ControlLabel SHALL expose `activate(): bool` through an Action identified as
`activate`. Pointer, keyboard and accessibility activation SHALL call the same
function. Disabled, non-clickable and empty labels SHALL return false and emit
no clicked intent; successful activation SHALL emit exactly once.

#### Scenario: Repeat activation through independent routes
- **WHEN** an enabled nonempty clickable label is clicked, keyboard-activated and triggered through its Action
- **THEN** each explicit operation produces one clicked intent, without synthesizing input for programmatic calls

#### Scenario: Caption or unavailable label is triggered
- **WHEN** a disabled, caption-only or empty label receives an activation request
- **THEN** no clicked intent is emitted and direct activation returns false

### Requirement: Keyboard and assistive activation are reachable
An actionable label SHALL be reachable and exitable using Tab/Backtab in a
focus-capable host. Enter, Return and Space SHALL activate it exactly once per
explicit key operation; auto-repeat SHALL NOT repeat activation. Losing focus,
becoming unavailable or losing content during a held operation SHALL cancel it.
It SHALL expose a caller-owned accessible name and Button press action, and
StateLayer SHALL show focus/press. Passive captions SHALL NOT add a Tab stop.

#### Scenario: Complete mute without a pointer
- **WHEN** a person tabs to an enabled label and presses Enter or Space
- **THEN** its shared operation is emitted once and Tab/Backtab can leave the label

#### Scenario: Held activation is cancelled
- **WHEN** a held activation loses focus or the label becomes disabled, empty or caption-only before completion
- **THEN** release does not activate the label or leave pressed state latched

### Requirement: Slider exposes its existing label operation
Slider SHALL expose `activateLabel(): bool` and append the `activate-label`
Action. Availability SHALL agree with enabled, labelClickable and nonempty label
content. Label clicked intent and Action triggers SHALL share that function,
emitting `labelClicked` once without mutating caller state. Existing four Action
positions SHALL remain stable and SHALL have stable named identifiers.

#### Scenario: External caller activates mute
- **WHEN** an enabled Slider with an actionable label receives activateLabel or an activate-label Action trigger
- **THEN** its host receives one labelClicked intent and decides the consequence, without a pointer event

#### Scenario: Slider label is passive
- **WHEN** a Slider has no label action or is disabled
- **THEN** its label Action is unavailable, activateLabel returns false and labelClicked is not emitted

### Requirement: Examples host the real operation without changing footprint
The existing Slider and SoundChannel examples SHALL answer label intent with
coherent mute state and SHALL preserve stored level during mute toggles. Their
programmatic mute route SHALL use Slider.activateLabel. Caption/action switching
SHALL NOT change label padding or its layout footprint, and label API targets
SHALL reference the actual readonly labelItem rather than a copied control.

#### Scenario: Mute and unmute in the sound composition
- **WHEN** the label is activated twice through real input or the declared action
- **THEN** host mute changes twice, the stored level is preserved and the real component emits the operation evidence
