# ListRow

The row: one item a person operates repeatedly; the host owns selection, values, optional inline expansion and the action's consequence. Activating an item never means advancing selection.
states: rest, hover, press, focus, selected (the accent at `opacitySelected` as a fill behind the row and the name in the accent, with no side marker), disabled and report-only; header and separator are structural rows a cursor steps past; disabled dims an unavailable action while a report-only row stays full-strength and simply is not a target; recede dims unpicked rows only in lists you pick from: text and glyph by colour (`Style.recede`), slotted content by `Style.opacityRecede`, reported as `receded`.
actions: `activate()` guards selectable and emits `activated`; StateLayer click, pointer, keyboard and programmatic routes share it; keyboard navigation and focus belong to the owning list through `focused`.
pointer: StateLayer grows the leading glyph only (by `growth`, in `size`); clickable trailing actions take their own grab, while passive readings remain part of the row target; hover reports `hoveredEntered` for the list cursor and wheel is not claimed.
keyboard: the owning list holds focus and routes arrows and Enter; the current row shows the focus ring on the body.
expected: the single-row unit owns focus and routes Enter through `activate()`; a physical trailing-action click reports only that action, body and passive-reading clicks activate the row, and long-content mode keeps both routes judgeable. Menu composition / Shell items hosts interaction between multiple rows and their editors; the row unit never implements a selector.
screen reader: selectable rows announce as buttons named by the primary label with the supporting text as description, `selected` and `selectable` as states, and `expandable` and `expanded` when they hold expansion content; structural and report-only rows are static text.
size: sm, md and lg resolve through the ListRow size table (32, 40, 56) with the glyph (`Style.glyphBeside` of the row height), the leading box (the glyph plus `space1`) and the text steps all derived from that height, and readonly `glyphSize` the glyph a host's own leading content takes; `headingHeight` is the host's absolute-height escape hatch, keeping body/input/editor origin aligned; readonly `expansionHeight` reports the actual revealed viewport for bounded surface sizing. Hosts never override total implicitHeight to set a heading. The asked width includes the inset the body gives away; long text elides and a supporting line that repeats the name hides.
tokens: the ListRow size table, icon and type scales, space scale, `opacitySelected` fill, opacity roles, surface ladder, accent, danger, Motion and StateLayer; no local colours or measurements.
motion: micro colour and opacity response; no position animation during a gesture; reduced motion shortens the durations.
expansion: host-owned `expanded` and named `expandedContent`; empty/structural rows reserve no editor space. Existing leading/trailing slots and heading size remain unchanged. The expansion is not a second row activation target; unavailable or collapsed content cannot handle input. Hosts choose the open/close consequence and focus destination.
alignment: readonly `contentInset` is the text column's leading edge. Expanded content starts there, directly beneath the heading, with Style.spaceTight top clearance and Style.space2 bottom clearance. No duplicate title or extra border; the same geometry hosts a slider or password form.
paint path: ListRow's host intent → clipped viewport height → full-size ColumnLayout slot at a fixed local origin below the heading → zero-height hidden viewport; content stays mounted. StateLayer/SelectionMark/body stay on the heading; no registry, shader or unload handoff is involved. Motion.fast/moveEasing reveal the viewport, not slider scaling; reduced motion removes that spatial reveal.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | transient shell action, adjust repeatedly without losing place | owner's keyboard contract | host-owned selection, controlled Slider | repeated activation and return focus |
| interaction | Enter/select opens; editor Enter/Escape returns to same item with applied value | no implicit advancement or hidden rollback | ListRow activation + expandedContent | keyboard/pointer/host flow |
| hierarchy/system | reading and disclosure cue on heading; horizontal editor directly below | local consequence, no popup or duplicate heading | Style row/type/space scales, Motion.fast | owner checks association and settled tail |
| responsive/state | fixed heading, elided text, full-width bounded slider; empty/disabled supported | component laws and blueprint | sm/md/lg, clip/input gate | owner review plus requested behavior check |

Not designed: multi-selection, nested disclosure, confirmation, asynchronous service results or a menu. No new tokens. APG Disclosure contributes explicit expansion, APG/Radix Slider its keys; Caelestia StyledSlider/MenuItem preserve input/intent separation. This is the existing row plus a content slot, not Disclosure's second heading.

## Measured

Unit `list-row` in a headless slot at scale 1.25 (md row, 800 px wide):

- Body inset 12 px both sides; leading box 20 px (glyph 16, centred at y 12); text column at x 40 (12 + 20 + 8); a two-line block of 28 px centred with 6 px above and below; trailing slot right edge at 788 (800 - 12), its action a 62 x 24 px target centred in the row. sm is 32 px (text block 2 px clear, so a supporting line at sm is tight), lg 56 px (glyph 24, text column at x 48).
- Hover grows the glyph from 16 to 19.2 px (2 device px a side) inside the 20 px box and lifts the surface from `#4e4159` to `#5b4f65`; press recolours and does not resize. The pointer zone is the painted row exactly: 40 logical px tall (y 156 to 195 probed one px at a time at 1.25).
- A click on the trailing action raises only `secondary-activated`; a click anywhere else on the row raises `activated`; a disabled, report-only or header row refuses the click (flow `list-row-pointer`, native pointer and native Enter, offscreen and in a window).
- Contrast: selected name 5.25:1 on the selected fill, muted line 5.09:1 on it, muted on band 8.61:1, text on band 13.71:1.

## Open

- The natural width follows the content (the body plus the two insets it gives away); a host that sizes by it, as `Menu` does by its widest row, states a width first.
