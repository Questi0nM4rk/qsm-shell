# Section

A titled group with a heading action and a content column; the header labels the group and the action acts on it.
states: none; the header shows only while a title or an action exists, and an empty action takes no space.
actions: none of its own; the heading `action` slot and the default `content` slot belong to the consumer.
pointer: none on the group itself; slotted controls keep their own targets and wheel passes through.
keyboard: none on the group itself; slotted controls keep their own tab stops and keys.
screen reader: the section title labels the group; the action and content name themselves.
size: content-driven column with fixed outer and body spacing; the heading row fills the width with the title taking the free space.
tokens: space1, space2 and Prose; no local colours or measurements.
motion: none.
not designed: collapsing, selection or scrolling; use Disclosure, Menu or ScrollArea for those.
