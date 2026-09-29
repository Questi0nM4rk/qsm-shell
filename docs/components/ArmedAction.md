# ArmedAction

A non-visual confirm-then-fire helper for destructive commands; the host owns the armed flag display and the action's consequence.
states: disarmed rest and armed intent; arming expires after `timeout` (3000 by default) and reports `disarmed`; with `destructive` false every trigger fires at once.
actions: `trigger()` arms a destructive command or fires when already armed, `disarm()` abandons the intent; pointer, keyboard and programmatic routes share them.
pointer: none; it paints nothing, takes no pointer and claims no events.
keyboard: none; the surface holding it routes keys to `trigger()` and `disarm()`.
screen reader: none; the visible control it guards supplies the accessible name and the armed announcement.
size: none; a QtObject with no footprint, no slots and no natural size.
tokens: none; no Style, Motion or colour roles of its own.
motion: none; arming is state, and any visible countdown belongs to the host.
not designed: the confirm control itself, policy, product consequence or persistence; use ActionTile, Capsule or the host for those.
