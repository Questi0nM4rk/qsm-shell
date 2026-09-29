# NotificationCard

One rich notification that expands on attention, swipes away and reports its actions; the host owns the entry model and every consequence.
states: collapsed and expanded; expansion follows attention, drag or pause, and archived entries read at rest; urgency sets the tick glyph and colour together.
actions: up to four entry actions plus swipe-dismiss in both directions and an opt-in vertical expand; middle click dismisses; `dismissed` and `actionTriggered(id)` report intent.
pointer: hover only reports; drag handles swipe and expand while the card keeps its action targets; wheel passes through.
keyboard: action focus moves by index with the focused action marked by colour, weight and underline; the card takes no text keys.
screen reader: app name, summary and body are text roles capped at six lines; each action carries its own accessible name.
size: fixed notification width with collapsed height; expanded height follows headline plus details; icon box, swatch radius and hit margins from tokens.
tokens: the notification size set, iconSm, radiusSm, space scale, danger, accent, text roles, divider inset and Motion; no local colours or measurements.
motion: entrance pop on opacity and scale, fast height settling and swipe translation; reduced motion shortens the durations.
not designed: history, search, grouping or stacking policy; use NotificationCenter, NotificationStack or the host for those.
