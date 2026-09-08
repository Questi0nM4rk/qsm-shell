# ADR 0001: Interactive controls stand on QtQuick.Templates

Date: 2026-09-09. Status: accepted.

## Context

47 types, none production ready. `TextField` alone needed a hand-drawn
caret, a caret inset fixed twice against a live ruler, and a width policy
fix because the box grew with its text. Every control was written from
`Rectangle` plus raw primitives, so focus, tab order, padding, the
disabled cascade and the keyboard route were reinvented per type and each
one missed something. There is no written definition of what a finished
component must do, so defects surface one at a time under a person's eyes.

caelestia-shell, the reference shell, builds 9 controls on
`QtQuick.Templates` and has them working under quickshell.

## Decision

1. Every control with a template counterpart stands on it: `T.TextField`,
   `T.Slider`, `T.RangeSlider`, `T.Switch`, `T.CheckBox`, `T.RadioButton`,
   `T.AbstractButton`, `T.DoubleSpinBox`, `T.TabBar`, `T.ScrollBar`. The
   template owns behaviour; the library owns looks through `Style`.
2. The popup family (`Menu`, `Popover`, `Dialog`, `ToolTip`) is decided by
   a spike: one `T.Popup` inside a `PanelWindow` with `NoAutoClose`. Until
   it passes, those types stay hand-rolled.
3. `StateLayer` keeps the five states and the growth-not-tint rule. When its
   host is a `T.Control` it reads `hovered`, `pressed`, `visualFocus` and
   `enabled` from the host instead of owning pointer handlers.
4. Every meaningful action is a function on the component and is listed in
   `readonly property list<Action> actions`, so a consumer's action menu can
   enumerate and trigger them. Pointer and keyboard routes call the same
   function. The library never sets `Action.shortcut`.
5. Code is copied from caelestia where it fits: template wiring, caret,
   control geometry, the `Anim` type-enum idea. `Tokens.*` reads become
   `Style.*`, M3 palette roles and the C++ plugin types are not ported.
   qsm-shell is GPL-3.0 as a consequence.
6. Standing ruling on the design-system blueprint: project tokens win.
   `icon.lg` moves from 26 to 24 to sit on the 4px rhythm; `controlHeight`
   stays 40.

## Definition of done for a component

1. Stands on its template where one exists.
2. Five states through `StateLayer`, plus its own (readOnly, failed,
   indeterminate) where they exist.
3. Every action is a function, listed in `actions`; pointer, keyboard and
   callers share it.
4. Natural size is a constant. Long content scrolls or elides, never grows
   the control.
5. Every number comes from `Style` or `Motion`.
6. `previews/units/<Type>.qml` with `controls` for states a pointer cannot
   reach; `tests/units/tst_<Type>.qml` with real events; `tst_units` walks
   `actions` and triggers each.
7. `ui-audit` and `ux-audit` against the live window with a tree dump;
   findings fixed or recorded in `docs/components/<Type>.md`.
8. The owner judges it in the live window.

## Consequences

- Public API breaks. `qsm-desktop` is updated after the controls land, not
  in lockstep.
- `docs/components/<Type>.md` is a new durable location: one short record
  per type (states, actions, size, tokens, motion, not designed,
  conflicts). `AGENTS.md` names it.
- The preview host grows a tree dump so audits have geometry without the
  consumer's `inspect` IPC.
