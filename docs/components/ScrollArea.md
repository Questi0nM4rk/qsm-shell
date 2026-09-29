# ScrollArea

An oriented scroll viewport with overflow furniture; content scrolls inside while a sibling cue paints fades and marks.
states: vertical and horizontal with matching flick direction and content extents; fade, indicator and overflow switch the chrome.
actions: none; no signals, no functions and no programmatic route beyond the exposed viewport.
pointer: the Flickable takes drag and wheel within bounds and stops at the edges; chrome never intercepts.
keyboard: none of its own; content keeps its own tab stops and keys.
screen reader: no role of its own; content names itself.
size: viewport-sized with no preset; fade depth is twice the large box step; model content uses ListView with a cue directly since Flickable nests none.
tokens: surface, space6 and ScrollCue; no local colours or measurements.
motion: none of its own; the Flickable and the cue own movement and fading.
not designed: the scrolled content, model delegates or scroll-to behaviour; use the host with ListView or a Flickable child for those.
