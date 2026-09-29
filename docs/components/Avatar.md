# Avatar

A masked person picture with a fallback glyph or initials, an optional presence dot and an optional progress ring; it reports identity and never takes input.
states: photo when the image is ready, icon fallback, initials fallback; a status dot shows only when `status` names a tone, a ring only while `progress` is set.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it never claims hover, press, focus or wheel.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surrounding row or surface names the person.
size: one `size` box for the picture; the implicit size grows by the ring gap plus ring width only while ringed; radius is half the size and the glyph is two fifths of it.
tokens: controlHeight, surfaceHover, accent, outline, spaceTight, textMuted, Prose and SvgIcon; no local colours or measurements.
motion: none; image, ring and dot settle without animation.
not designed: selection, action, editing, a badge count or a menu; use Badge, IconButton or the host for those.
