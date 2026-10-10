## ADDED Requirements

### Requirement: Container content and visibility remain host-owned
DataCapsule SHALL be a general T.Control with an arbitrary content slot, not a
Capsule button, Rollout variant or audio widget. It SHALL render host-owned shown
state and emit activation/timeout intent without mutating host visibility or
invoking services. Pointer, keyboard, accessibility and programmatic activation
SHALL use the same public action and refuse when hidden, disabled or report-only.

#### Scenario: Host does not answer timeout intent
- **WHEN** a positive timeout expires and the host leaves shown true
- **THEN** one timeoutRequested is emitted and the container does not close itself or repeatedly expire without a new presentation

#### Scenario: Nested control acts independently
- **WHEN** a slot control or its action is activated
- **THEN** its own intent reaches its host without also activating the capsule body

### Requirement: Lifetime supports persistent presentation and retained interaction
Timeout zero SHALL be persistent. Positive timeouts SHALL support remaining-budget
pause during hoverStay and keyboard focus, restart on explicit presentation, and
cancellation on reset/host hide. Reduced motion SHALL NOT shorten timeout budget.

#### Scenario: Pointer crosses onto a slot action
- **WHEN** a timed capsule is hovered over its nested interactive content
- **THEN** hover retention remains active without stealing that content's hover and expiry resumes with the remaining budget after retention ends

#### Scenario: Reset cancels a pending expiry
- **WHEN** reset or host hide occurs before expiry
- **THEN** no later timeout intent fires from that cancelled presentation and a subsequent presentation can expire normally

### Requirement: Size and material remain general and theme-driven
The container SHALL expose horizontal/vertical body sizing, theme presets,
preferred-length and direct body-size escape hatches. Natural size SHALL NOT be
derived from slot text. Body material SHALL default to Style.bandFill and use
existing radius/elevation tokens, reversible opacity fades and reduced-effects
support. Orientation SHALL NOT rotate arbitrary content or choose its layout.

#### Scenario: Change orientation with long content
- **WHEN** a host changes orientation or preferred footprint while content is long
- **THEN** body sizing follows the requested dimensions without growing from text and the host-provided content stays within its slot

#### Scenario: Effects are reduced during presentation
- **WHEN** reduced-effects or reduced-motion settings change
- **THEN** elevation/fade obey the current Style/Motion settings without altering the stored content or timeout policy

### Requirement: Base story is content-neutral and exposes meaningful states
The sole DataCapsule unit SHALL show the general container on the shared mock
screen, with short/long/empty neutral content. It SHALL expose edges, alignment,
insets, orientation, size/length, visibility, lifetime, retention, elevation and
availability through declared controls. It SHALL NOT embed sound-specific state.

#### Scenario: Inspect the base instead of an audio composition
- **WHEN** the owner selects DataCapsule from the shell catalog
- **THEN** its neutral base is rendered, position controls affect the real container and all advertised supported cases are reachable

#### Scenario: Act on a report-only or disabled base
- **WHEN** pointer, keyboard or programmatic activation is attempted in either state
- **THEN** no body action is falsely reported as successful; report-only content remains legible and disabled input is unavailable

### Requirement: Base controls separate independent choices from commands
The base SHALL declare separate choice groups for edge, alignment, inset,
orientation, size, length, content, lifetime, retention, elevation and availability.
Presentation commands SHALL have their own group. Regrouping SHALL preserve
component behavior and the meaning of every action, with matching exact flow names.

#### Scenario: Change size without changing orientation
- **WHEN** the owner selects a size option from its own labelled group
- **THEN** orientation and length remain unchanged and their choices remain in their own groups
