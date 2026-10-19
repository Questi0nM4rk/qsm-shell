# Segmented

## Production record

`Segmented` is a small, horizontal one-of-N control for panel tabs and value
choices. The host owns `currentIndex`; `selected(index)` reports intent and the
host answers it. `options` accepts labels or objects with `label`, `icon`,
`badge`, and `disabled`.

Settings are `options`, `currentIndex`, `enabled`, the free-set `size`
preset (`sm`, `md`, `lg`, or a consumer-defined name); `barHeight` remains
the direct sizing escape hatch. Segments are equal-width, fixed-natural-width,
single-line, and elide long labels. Empty icon and badge slots cost no space.

`tabNavigation` opts into an owner's Tab/Shift+Tab selection contract while
focus is inside this one group; the default stays the conventional single tab
stop. `wrapNavigation` defaults to true; a group whose ends are visible
landmarks sets it false. Tab, Backtab, arrows and the actions share one
`step` route, unavailable options are skipped, modified keys are left alone,
and focus stays in the group. Nothing here reaches a sibling editor's typing.
This is an explicit departure from the usual Tab-leaves-a-tablist pattern,
asked for by one consumer, not a new default for everyone. Caelestia's native
TabBar ownership is reused, not its separate wheel handling or indicator.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | Choose one shell section without leaving the group | Owner's panel task; auxiliary transient surface | T.TabBar | Keyboard section switching |
| interaction | Opt-in Tab/Backtab reuses `step` and skips unavailable options | Owner contract; conventional arrows retained | select/step | Forward, reverse, endpoints, unavailable |
| hierarchy/token | The existing quiet equal-cell group and focus ring, unchanged | No visual redesign was asked for | Style size/text/state scales | Owner live review |
| responsive/state | Fixed natural size, elided labels, no movement when all options are unavailable | Component laws | Style.controlWidth, StateLayer | Empty/long/disabled unit cases |
| polish | No new motion or colour | Accepted direction | Style/Motion | Owner live review |

Pointer selection, Space/Enter activation, horizontal arrows, Home/End, and
the `Previous`, `Next`, `First`, and `Last` actions use the same selection
route. Arrows wrap and skip disabled options; Home/End choose the first/last
enabled option, including when an endpoint is disabled. RTL follows the visual
arrow direction. Focus is one native tab stop into the selected/first item;
the template provides tab semantics and screen-reader selected/disabled state.

The unit must make first, middle, last and all-disabled cases reachable,
including a selected option becoming unavailable. A middle-only switch does
not represent per-option availability. Sample labels and optional glyphs name
one coherent choice; the owner accepts the fixture and interaction before the
next type starts.

The bar has `sm` (32), `md` (40), and `lg` (52) heights. One scale from
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
