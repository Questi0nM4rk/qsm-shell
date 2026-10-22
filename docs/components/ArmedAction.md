# ArmedAction

A non-visual confirm-then-fire helper for destructive commands; the host owns the armed display and the action's consequence.
states: disarmed rest and armed intent; arming expires after `timeout` (3000 ms by default) and reports `disarmed` (a confirmed fire does not); with `destructive` false every trigger fires at once, so a control keeps one code path for "this one asks" and "this one does not".
actions: `trigger()` arms a destructive command or fires when already armed, `disarm()` abandons the intent; pointer, keyboard and programmatic routes share them. Changing `destructive` while armed disarms.
pointer: none; it paints nothing and takes no pointer. The host calls `disarm()` when the pointer leaves the control it guards (`hovered` on a T.Control with `hoverEnabled`, or an `exited` signal such as ActionTile's).
keyboard: none; the surface holding it routes keys to `trigger()` and `disarm()`, and disarms when its focus leaves.
screen reader: none; the guarded control supplies the accessible name and changes it while armed (ActionTile names itself `confirmLabel`, an IconButton's `accessibleName` follows `armed`).
size: none; a QtObject with no footprint, slots or natural size.
tokens: none; no Style, Motion or colour roles of its own.
motion: none; arming is state, and any visible countdown belongs to the host.
not designed: the confirm control itself, policy, persistence, extending the window or an invalid `timeout` (0 expires on the next event loop and a destructive command then cannot be confirmed). The ladder it sits on: constraint, safe default, consequence preview, undo, then confirmation; a routine action that confirms trains the reflex click that removes the protection.

## Contract

- Public: `destructive` (true), `timeout` (3000), `armed` (read-only), `trigger()`, `disarm()`, `fired`, `disarmed`.
- Armed to fired clears `armed` and stops the timer without `disarmed`; armed to timeout, `disarm()` or `destructive` changing emits `disarmed` once.
- The unit (`workbench/units/ArmedAction.qml`) is the notification center's clear button: an IconButton that asks twice, with the pointer leaving, focus leaving and the timeout disarming it. Both wordings take the longer one's width, so arming never moves the button under the pointer. Its flow drives real clicks, the pointer leaving, Space, Enter, `disarm`, the expiry and the safe guard.

## Measured

| what | value |
| --- | --- |
| armed, then screenshot at +2.5 s | still armed |
| armed, then screenshot at +3.7 s | expired, wording and colour back |
| `await armed false` after one arm, flow | 3.0 s (flow total 3.4 s including startup) |
| confirmed fire | `fired` 1, `disarmed` 0 |
