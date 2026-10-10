## ADDED Requirements

### Requirement: Shell fixture renders a labelled desktop and fullscreen mock
The shell provider SHALL offer one shared mock-screen fixture consuming the
read-only harness environment. Desktop mode SHALL show the real ShellBorder and
an inset mock application; fullscreen mode SHALL hide the frame and let the mock
application fill screenRect. It SHALL clearly identify the environment as simulated.

#### Scenario: Switch the application into simulated fullscreen
- **WHEN** the harness toggles fullscreen preview
- **THEN** the mock application fills the logical screen, the frame disappears, and overlay content stays in the same fixture instance

#### Scenario: Standalone fixture without harness context
- **WHEN** the fixture is constructed without previewEnvironment
- **THEN** it renders explicit desktop simulation from its bounds and does not claim harness fullscreen capability

### Requirement: One screen-relative placement rule serves base and compose
The shared fixture SHALL place overlay bodies by edge, start/center/end alignment
and non-negative inset relative to screenRect. Actual body geometry SHALL fit the
inset screen bounds; preferred dimensions SHALL stay unchanged, and constrained
placement SHALL be observable. Left/right alignment SHALL run top-to-bottom;
top/bottom SHALL run left-to-right. Shadows SHALL NOT enlarge interactive bounds.

#### Scenario: Move a capsule between edges
- **WHEN** edge, alignment, inset or orientation changes through declared controls
- **THEN** the same capsule is repositioned against the mock screen, retains its host state and remains operable where a valid body fits

#### Scenario: Footprint cannot fit
- **WHEN** preferred dimensions exceed the inset bounds or inset consumes the screen
- **THEN** the host reports constrained placement, clips actual body to valid bounds and offers no native target for an empty body

### Requirement: Only the shell provider owns mock geometry and styling
The mock fixture SHALL use existing Style and ShellBorder vocabulary and SHALL
NOT introduce production services or a third provider. The library DataCapsule
SHALL remain unaware of screens, workbench chrome, compositor masks and frame policy.

#### Scenario: Base and composition use the same placement
- **WHEN** the same placement settings are selected in the base story and a composition
- **THEN** both use the shared fixture geometry rather than separately implemented edge algorithms
