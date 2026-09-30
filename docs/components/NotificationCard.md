# NotificationCard

One rich notification that expands on attention, swipes away and reports its actions; the host owns the entry model and every consequence.
states: collapsed and expanded; expansion follows attention, drag or pause, and archived entries read at rest; urgency sets the tick glyph and colour together.
actions: enumerated `dismiss()` and `activateAction(id)` share real gesture, middle-click and entry-action routes. At most three entry actions are displayed and enumerated; archived entries retain dismissal intent but do not offer entry actions. The host answers `dismissed` and `actionTriggered(id)`.
pointer: hover only reports; drag handles swipe and expand while the card keeps its action targets; wheel passes through.
keyboard: action focus moves by index with the focused action marked by colour, weight and underline; the card takes no text keys.
screen reader: app name, summary and body are text roles capped at six lines; each action carries its own accessible name.
size: fixed notification width with collapsed height; expanded height follows headline plus details; icon box, swatch radius and hit margins from tokens.
tokens: the notification size set, iconSm, radiusSm, space scale, danger, accent, text roles, divider inset and Motion; no local colours or measurements.
motion: entrance pop on opacity and scale, fast height settling and swipe translation; reduced motion shortens the durations.
expected: enumerated `dismiss()` and `activateAction(id)` share the pointer/gesture intent functions. Only a displayed, valid entry action can report its id; unavailable or unknown ids report nothing. Actions never mutate `entry`, archive it or remove the card; the host owns consequences.
not designed: history, search, grouping or stacking policy; use NotificationCenter, NotificationStack or the host for those.
