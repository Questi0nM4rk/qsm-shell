# Segmented

## Production record

`Segmented` is a small, horizontal one-of-N control for panel tabs and value
choices. The host owns `currentIndex`; `selected(index)` reports intent and the
host answers it. `options` accepts labels or objects with `label`, `icon`,
`badge`, and `disabled`.

Settings are `options`, `currentIndex`, `enabled`, and the free-set `size`
preset (`sm`, `md`, `lg`, or a consumer-defined name); `barHeight` remains the
direct sizing escape hatch. Segments are equal-width, fixed-natural-width,
single-line, and elide long labels. Empty icon and badge slots cost no space.

Pointer selection, Space/Enter activation, horizontal arrows, Home/End, and
the `Previous`, `Next`, `First`, and `Last` actions use the same selection
route. Arrows wrap and skip disabled options; Home/End choose the first/last
enabled option, including when an endpoint is disabled. RTL follows the visual
arrow direction. Focus is one native tab stop into the selected/first item;
the template provides tab semantics and screen-reader selected/disabled state.

The bar has `sm` (32), `md` (40), and `lg` (52) heights. One `sizeScale` from
the bar height scales text, glyphs, spacing, and insets through the Style
helpers; radius, focus gap, and borders do not scale. Rest, hover, pressed,
focused, selected, and disabled states are explicit. Disabled roles are dimmed
by colour, never composite opacity. Selection is accent identity over one
outer Surface body.

Events are the `selected(index)` intent signal and the inherited template
pointer/focus/accessibility events. A small visible set is required; this type
is not designed for vertical orientation, scrolling many options, wrapping
labels, or a gliding cross-cell indicator (the latter remains an owner
question).

Sources: Qt `TabBar`/`TabButton` template semantics; WAI-ARIA tabs keyboard
pattern; Radix ToggleGroup; Fluent fixed tab sets; shadcn size/disabled/RTL
group conventions; Caelestia `Tabs.qml`; `docs/adr/0001-controls-on-templates.md`.
