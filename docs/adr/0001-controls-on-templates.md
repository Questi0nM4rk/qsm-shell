# ADR 0001: Interactive controls stand on QtQuick.Templates

## Context

Every control was written from `Rectangle` plus raw primitives, so focus,
tab order, padding, the disabled cascade and the keyboard route were
reinvented per type and each one missed something. caelestia-shell, the
reference shell, builds its controls on `QtQuick.Templates` and has them
working under quickshell.

## Decision

1. Every control with a template counterpart stands on it: `T.TextField`,
   `T.Slider`, `T.RangeSlider`, `T.Switch`, `T.CheckBox`, `T.RadioButton`,
   `T.AbstractButton`, `T.DoubleSpinBox`, `T.TabBar`, `T.ScrollBar`. The
   template owns behaviour; the library owns looks through `Style`.
2. The popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) stays
   hand-rolled: `T.Popup` inside a `PanelWindow` paints only inside the
   window rect.
3. `StateLayer` keeps the five states and the growth-not-tint rule. When its
   host is a `T.Control` it reads `hovered`, `pressed`, `activeFocus` and
   `enabled` from the host instead of owning pointer handlers.
4. Every meaningful action is a function on the component and is listed in
   `readonly property list<Action> actions`, so a consumer's action menu can
   enumerate and trigger them. The library never sets `Action.shortcut`.
5. Code is copied from caelestia where it fits: template wiring, caret,
   control geometry, the `Anim` type-enum idea. `Tokens.*` reads become
   `Style.*`; M3 palette roles and the C++ plugin types are not ported.
   qsm-shell is GPL-3.0 as a consequence.
6. Project tokens win over the design-system blueprint where they disagree.
   `icon.lg` is 24 to sit on the 4px rhythm; `controlHeight` stays 40.

## Consequences

- Public API breaks. `qsm-desktop` is updated after the controls land, not
  in lockstep.
- The definition of done for a component lives in `AGENTS.md`.
