# Section

A titled group with a heading action and a content column; the header labels the group and the action acts on it.
states: none; the header shows only while a title or an action exists, and an empty action takes no space.
actions: none of its own; the heading `action` slot and the default `content` slot belong to the consumer.
pointer: none on the group itself; slotted controls keep their own targets and wheel passes through.
keyboard: none on the group itself; slotted controls keep their own tab stops and keys.
screen reader: a named group whose title is a heading; the action and content name themselves.
size: content-driven column; it claims no space outside itself (the owning surface sets the gap before a section), its rows hang `space1` below the heading and `space1` apart; the heading row fills the width with the title taking the free space.
tokens: space1 and Prose; no local colours or measurements.
motion: none.
not designed: collapsing, selection or scrolling; use Disclosure, Menu or ScrollArea for those.

## Measured

Unit `section` in a headless slot at scale 1.25, 380 px wide:

- The heading row is as tall as its action (32 px with a `sm` Capsule, 70 px wide at the right edge); the title is 14.4 px tall (18 device px, whole through Prose), centred at y 9 of 32 (a layout places it on a whole logical pixel). Rows hang 4 px below it and 4 px apart (heading bottom 32, first row at 36).
- The action takes a native click (flow `section-header`, offscreen and in a window), also after the title is cleared; a group with no title and no action shows no heading and takes no space.
- Hit zones: the action is the 70 x 32 px Capsule, above the 24 px floor; the title and the rows take no input.
- The title is an `Accessible.Heading`; the group is a named `Accessible.Grouping`.
