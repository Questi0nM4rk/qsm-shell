# NotificationCenter

A searchable history of notifications grouped by application; it filters, groups and navigates, and the host owns dismissal and consequence.
states: empty and list; live entries sort above archived within each application group; do-not-disturb and clear ride Capsule controls.
actions: `focusField`, `moveSelection`, `activateSelected`, `removeSelected` and `moveAction` share one keyboard route; hover, dismiss and action intents report upward and never resolve inside.
pointer: hover selects only while the pointer owns selection; rows keep their own targets and wheel scrolls the list.
keyboard: the search field holds focus and routes Up and Down to selection with `selectionClaimed`; accept activates and Escape reports outward; unclaimed keys report through one hook.
expected: entry-action navigation visits only enabled actions exposed by the selected NotificationCard; activation and dismissal call that card's functions, so archived, hidden, disabled and stale action targets cannot bypass its guards. No intent mutates the host's entries.
sorting: copy entries before sorting, group by application, live before archived and newest within each group; equal-recency groups retain feed order. Search includes the application name. Archive identity uses `archiveId` when supplied, with a legacy timestamp/content key otherwise. Dismissal reports the record to its host for removal; snapshot updates preserve delegates so hover/pause cannot recreate the hovered card.
sources: caelestia `StyledTextField.qml` supplies the focused search-field pattern, not notification routing or its host-side validation; Radix Toolbar supplies the keyboard-navigation reference. NotificationCard owns entry-action availability; the center adds search and a shared cursor rather than a second card policy.
screen reader: application sections label their groups; the search field, rows and actions name themselves; empty states announce no matches or nothing here.
size: list height follows content up to a maximum with a two-row floor; fixed header, list and section spacing; the container follows its content.
tokens: space scale, iconMd, textMuted, surface, TextField, Capsule, ListView, ScrollCue and EmptyState; no local colours or measurements.
motion: none of its own; cards and cues settle their own changes.
not designed: live ephemeral display, swipe physics or dismissal itself; use NotificationStack, NotificationCard or the host for those.
