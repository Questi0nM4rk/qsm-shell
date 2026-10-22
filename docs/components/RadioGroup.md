# RadioGroup

One exclusive choice made of `Radio` children (owner: "Přidat."). The group is the keyboard and screen-reader half; each `Radio` keeps its look and pointer behaviour. The host owns `currentIndex` and answers `selected(index)`; the group never writes it.
states: the group dims by colour when disabled (children follow); each child keeps its own five states; an unavailable child is skipped by every key
actions: Previous, Next, First, Last; `select(index)`, `step(delta)`, `first()`, `last()` share one route with the pointer, which is the child's own `select()` answered by `selected(index)` once per real change
keys: one Tab stop for the whole group, on the checked radio (the first available one while none is checked); Down and Right go next, Up and Left previous (an RTL group swaps the horizontal pair), wrapping unless `wrapNavigation` is false; Home and End the first and last available; a key moves focus AND selects, and the ring shows on the focused radio; modified keys are left alone; Space and Return stay the radio's own
content: the default slot takes `Radio` children (a `Repeater` of them works); the group sets each child's `checked` from `currentIndex`, so a child carries no `checked` binding; `label` is a `ControlLabel` above the options, `optionSpacing` (default `Style.space2`) sits between them
accessibility: group role `Grouping` named by `label`, its description is the checked option's name; each child is a `RadioButton` with `Accessible.checked`
tokens: space2 (spacing); everything else is Radio's and ControlLabel's
base: `T.Control`; children are found by `select()` and `selectionRequested`, so any type with that shape joins
not designed: horizontal layout, a group inside a group
