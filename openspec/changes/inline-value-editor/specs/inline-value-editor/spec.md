## ADDED Requirements

### Requirement: Row expansion remains host-controlled
ListRow SHALL accept host-owned expanded state and named expandedContent. Its
existing heading and trailing slots SHALL remain compatible. Activation SHALL
only report intent, without writing selection, expanded state or editor value.
An empty slot, header or separator SHALL NOT reserve editor space. The full
editor SHALL be revealed below the fixed heading through a clip, without scaling
its control geometry; reduced motion SHALL remove the spatial reveal.

#### Scenario: Host opens an inline value editor
- **WHEN** a host answers the selected row's activation with expanded true
- **THEN** the supplied horizontal slider appears beneath that heading without the row selecting another item or mutating its value

#### Scenario: Editor closes or is empty
- **WHEN** a host closes the editor or supplies no expanded content
- **THEN** hidden content cannot receive input, its space becomes zero, and the existing heading remains usable

### Requirement: Slider bindings are shared and configurable
Slider SHALL use shared decrease/increase bindings defaulting to N/O alongside
its existing arrows, active-thumb logic and public actions. Each binding SHALL
be configurable globally through Interaction and overridable per instance.
Zero SHALL disable the respective custom binding; equal custom bindings SHALL
be ignored. Custom keys SHALL operate only on focused sliders, SHALL NOT consume
Ctrl/Alt/Meta combinations or searchable text input, and SHALL share stepBy and
commit semantics rather than synthesize arrow events.

#### Scenario: Repeat nudges with the default bindings
- **WHEN** a focused horizontal or vertical slider receives N or O
- **THEN** its active value decreases or increases through the existing controlled route and its host observes the changed value and completed gesture

#### Scenario: Caller changes the bindings
- **WHEN** the shared bindings or an instance override change
- **THEN** that slider uses the configured keys and no longer responds to replaced custom keys, while arrows and value bounds continue to work

#### Scenario: Keyboard interaction is interrupted
- **WHEN** focus or availability is lost during a held value key
- **THEN** later release does not produce a stale commit or mutate an unavailable control

### Requirement: Inline editing preserves the user's place
The native menu composition SHALL retain the same selected item across repeated
activation and value changes. Enter or general activation SHALL reveal its
horizontal editor and make it keyboard-operable. Enter/Escape from the editor
SHALL close it, preserve the applied value and restore focus to the same item.
Navigation and Tab/Backtab SHALL remain reachable without trapping focus.
Slider SHALL expose a live keyPressed event hook before its template processing
so an inline-editor host can claim navigation without replacing value handling.
Up/down from a focused editor SHALL use Menu stepping, selecting the next
available visible item rather than editing the value or reimplementing a selector.

#### Scenario: Navigate out of an expanded editor
- **WHEN** Up or Down is pressed while adjusting a value or typing a Wi-Fi password
- **THEN** Menu selects the previous or next selectable item, closes the old expansion and keeps applied values or an unsubmitted password draft

#### Scenario: Adjust then repeat an action
- **WHEN** a user opens Output volume, adjusts it with arrows or N/O and exits with Enter or Escape
- **THEN** the value is retained and the next activation targets that same Output volume item instead of jumping to another result

#### Scenario: Repeat a toggle on its item
- **WHEN** the selected mute item is activated several times
- **THEN** its state toggles once per explicit operation while selection remains on mute and stored level remains unchanged

### Requirement: Component and host routes remain honest
Pointer, keyboard and programmatic routes SHALL use the actual row/slider
functions and host callbacks. Slider pointer input SHALL NOT activate the row
above. Disabled operations SHALL refuse mutation and actions SHALL report refusal
truthfully. The current value, expanded state and selected item SHALL be visible
to the owner and observable in focused integration checks.

#### Scenario: Pointer operates the editor
- **WHEN** the opened Slider is clicked or dragged
- **THEN** its host updates the value without an extra row activation or unintended selection change

#### Scenario: Search receives binding characters
- **WHEN** N/O are typed into the example's focused search field
- **THEN** they edit text without changing a slider value

### Requirement: One composition hosts the menu item interactions
The review item SHALL assemble actual Menu and shell controls in one native QML
composition containing value, ON/OFF, Wi-Fi secure/open networks, Bluetooth/BLE
devices, plain/secondary actions, headers, separators, unavailable and read-only
rows. Vertical content SHALL remain a single scrolling column during expansion.
Editors SHALL align beneath the item's text column, without a duplicate volume
title. Menu keyboard activation SHALL use the same row activation function as
pointer and programmatic routes. ListRow's unit SHALL NOT implement another menu.

#### Scenario: Try a secured network locally
- **WHEN** the secure Wi-Fi item is activated and its password is submitted
- **THEN** the local fixture reports pending and success or failure, retains selection, permits retry without losing the draft, and performs no real network or persistence operation

#### Scenario: Toggle a radio or connect a device
- **WHEN** a row or its Switch is activated, or a Bluetooth/BLE device operation is requested
- **THEN** the same host operation answers the intent once, dependent availability and displayed outcome update, and selection stays on the operated item

#### Scenario: Reset with work pending
- **WHEN** the composition is reset during a simulated connection or scan
- **THEN** pending work is cancelled, transient drafts are cleared and no later reply changes the reset state
