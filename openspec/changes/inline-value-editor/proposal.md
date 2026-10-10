## Why

Keyboard users must be able to repeat an action without losing their place and
adjust a value directly beneath its item. This shell-first item supplies the
reusable controls; desktop action-menu wiring follows owner review, not a backend
overhaul.

## What Changes

- Add an optional host-controlled expansion slot to the existing ListRow.
- Give every Slider shared, bindable decrease/increase keys, defaulting to N/O,
  alongside its current arrows and public step functions.
- Prepare one native menu composition with value, ON/OFF, Wi-Fi password,
  Bluetooth/BLE device, plain/secondary action and nonselectable items together.
  Existing Menu owns stepping; expanded editors remain attached to their item.
  Up/down move between items even from an editor; left/right or N/O adjust volume.
- Run requested focused real-QML input/host checks. No catalog review sweep.

## Capabilities

### New Capabilities
- `inline-value-editor`: host-controlled inline row editing and shared slider keys.

### Modified Capabilities
None; durable OpenSpec specs are empty. Existing component records are revised
before implementation.

## Impact

ListRow, Slider, Interaction and Menu, their current records, a native QML menu
composition registered in the existing catalog, and the affected focused check.
ListRow's unit returns to demonstrating one row. No new component type, services,
dependency, persistence, JSON composition framework or Workbench-core redesign.

## Critiques

- Devil's advocate: a retained index is insufficient if activation or a model
  refresh steals focus. Exercise repeated real Enter and editor open/adjust/close
  on the same named item; desktop model-identity repair remains consumer work.
- Future archaeologist: separate layout disclosure from the operation. The host
  owns expanded/value/selection and focus policy; default keys are shared facts,
  not an implementation copied into each frontend.
- Scope sniper: extend ListRow and Slider, not a new action-menu framework,
  backend API, nested-disclosure component or notification migration.
- Owner review: the detached two-row example was not accepted. Replace it with
  one Menu composition; do not reproduce Menu navigation inside a ListRow unit.
  A tighter text-column editor without a duplicate label addresses the separation.

Findings are addressed in the design and scenarios. Owner acceptance and
production launcher behavior remain explicitly separate from test evidence.
