## Why

The desktop OSD story must address the actual Slider label action without scanning
private child object names. A readonly reference makes that public composition
boundary explicit without adding desktop policy to the library.

## What Changes

- Expose `labelItem` as a readonly reference to the existing ControlLabel.
- Keep label geometry, settings, pointer/keyboard/focus/accessibility routes,
  sizes, overflow, action signals and rendering unchanged.
- Document the public reference in the Slider record and interaction spec.

## Capabilities

### New Capabilities
- `slider-label-target`: direct public reference to the real label control.

### Modified Capabilities
None.

## Impact

Slider.qml and its component record only; no consumer behavior or new tokens.

## Critiques

- Devil's advocate: a target could become a second action route. Addressed by
  referencing the existing ControlLabel; no new handler or synthesized event.
- Future archaeologist: objectName is not a durable API. Addressed by an explicit
  typed readonly property, documented as the same control.
- Scope sniper: adding a target registry to every component is unnecessary.
  Addressed by this one reference only.
