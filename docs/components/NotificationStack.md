# NotificationStack

The live ephemeral stack of notifications in a deterministic order; it places cards, evicts the oldest and reports geometry for the shell edge.
states: visible cards newest-first with evicting snapshots sliding out above; the display list is retained while eviction settles so nothing jumps.
actions: none of its own; cards report dismiss and hover upward and the host owns the stack model and liveness.
pointer: cards keep swipe and action targets; the stack claims no events and wheel passes through.
keyboard: none of its own; cards keep their action focus behaviour.
screen reader: cards announce themselves; the stack adds no role beyond ordering.
size: width follows the column and height subtracts the evicting share; cards share the collapsed notification height with no gaps.
tokens: notificationCollapsedHeight and the reveal Motion set; cards bring their own roles.
motion: reveal curve on eviction shift and column moves; reduced motion shortens the durations.
not designed: history, search, grouping or card content; use NotificationCenter, NotificationCard or the host for those.
