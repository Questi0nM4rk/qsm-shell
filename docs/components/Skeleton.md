# Skeleton

A loading placeholder that holds the shape of content still arriving; it reserves space and never carries meaning.
states: block and line; a line takes its height from its Prose role and a pill radius, while a block uses the control height and small radius.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; it is a placeholder with no accessible name until real content lands.
size: width is a fraction of the control width and never content-derived; line height follows the role scale from hero to metadata.
tokens: controlHeight, controlWidth, radiusSm, surfaceHover and the text scale; no local colours or measurements.
motion: an infinite opacity pulse while visible; reduced motion lengthens the period.
not designed: progress values, error copy or empty explanation; use ProgressBar, Callout or EmptyState for those.
