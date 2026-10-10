# Menu

A keyboard-navigable container for rows; the host owns the model, the delegate and what activation does.
states: one `currentIndex` cursor over visible/selectable rows; navigation wraps, skipping headers, separators, disabled and report-only entries.
actions: `step(delta)` moves the cursor; `activateCurrent()` calls the selected row's `activate()` and reports `activated(index)` through the same route as a pointer. `rowAt(index)` and `rowCount` let hosts resolve identity and scroll the actual item into view. Static content and model with delegate feed the same rows.
pointer: rows keep their own targets; the container claims no clicks and wheel passes through.
keyboard: arrows step along the orientation and Return and Enter activate the current row; the container holds focus for its rows.
screen reader: rows name themselves; the container adds no role beyond grouping.
size: rows stretch across the container on the cross axis; natural size follows content. The main axis is unconstrained, so expanded entries never wrap into a second column. A ScrollArea in the owning composition bounds overflow.
tokens: space1 only; rows bring their own type, icon and space scales.
motion: none of its own; rows settle their own state changes.
not designed: the row itself, popover placement or dismissal; use ListRow, Popover or the host for those.

expected: shell Workbench → Compositions → menu-items contains Wi-Fi secure/open networks, BLE devices, ON/OFF switches, volume/mute, plain/secondary actions and unavailable/report-only/structural rows. Up/down selects items even from editors; left/right/N/O adjusts volume; password typing remains text. Enter/Escape returns from volume to its own item. Pointer and row activation answer the same operation once. Local fixtures show connection progress, retry and outcomes without hardware or password persistence; reset cancels them. The provider's menu-items JSON hosts one native MenuInteractions fixture; it is not a component story or another production component type.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | transient desktop actions, reviewed together in one composition | owner wants control interactions, not another selector in a row | Menu + existing controls | owner completes value/toggle/connect routes |
| ia/interaction | audio, Wi-Fi, Bluetooth groups; one cursor, one row route; up/down always navigates | owner's keyboard contract; Caelestia MenuItem separates intent; APG menu uses arrow stepping | Menu.step/activateCurrent, Slider/TextField key hook | actual repeated keys and pointer operations |
| hierarchy/token | compact editor beneath the text column, no duplicate Volume label or extra box | owner rejected detached slider; blueprint rhythm and hierarchy | ListRow.contentInset, Style.spaceTight/space2; existing type scale | owner judges association and reveal |
| responsive/state | one scrollable column; availability follows radios; pending/failure/retry; drafts retained until reset | hidden input must not activate; no lost work or fabricated production success | ScrollArea, Field, cancellable local fixture | keyboard into view, radio off, submit/retry/reset |
| polish | restrained common surface, motion only for disclosure/state | Quiet Luminous and reduced-motion law | Style.surfaceRaised/radiusLg, Motion.fast | owner review, no automatic audit |

Not designed: real network/audio services, production action-menu identity repair,
arbitrary nested menus, screen-reader speech verification or a JSON menu framework.
No new design tokens. APG's action-only menu is not an ARIA role claim for this
mixed-control native composition; each actual control keeps its own accessible name.
