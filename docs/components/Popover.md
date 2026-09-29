# Popover

Anchored floating content that flips to the side with the most room and clamps into bounds; it places and reports, and the surface decides open state.
states: open and closed with an opacity and offset settle between them; hover, press and manual triggers arm open and close delays; the shown side follows fit, not the request.
actions: none of its own; `openRequested` and `dismissRequested` report intent and Escape reports dismissal; open state never changes inside.
pointer: hover and press triggers read handlers on the anchor and the popover keeps its own targets; wheel passes through.
keyboard: Escape reports dismissal; the content keeps its own tab stops and keys.
screen reader: no role of its own; the anchored content names itself.
size: content size with a fixed anchor gap; placement resamples every frame while settling so anchor and bounds moves are followed.
tokens: space2 and the Motion delay and easing set; no local colours or measurements.
motion: emphasized entry and standard exit on opacity and offset; reduced motion shortens the durations.
not designed: modal takeover, focus trapping or dismissal policy; use Dialog, Rollout or the host for those.
