# Menu

A keyboard-navigable container for rows; the host owns the model, the delegate and what activation does.
states: one `currentIndex` cursor over visible/selectable rows; navigation wraps, skipping headers, separators, disabled and report-only entries; one selection thumb slides between rows and carries the keyboard ring; `enabled: false` dims the whole menu once, toward the band by the disabled share.
actions: `step(delta)` and `stepToEdge(first)` move the cursor; `activateCurrent()` calls the selected row's `activate()` and reports `activated(index)` through the same route as a pointer; all are listed in `actions` (step-previous, step-next, step-first, step-last, activate-current). `rowAt(index)` and `rowCount` let hosts resolve identity and scroll the actual item into view. Static content and model with delegate feed the same rows.
boundary: `rowAt` exposes an Item for positioning/native input; activation keeps the consumer row's full protocol from the registry, without pretending every delegate is only a generic Item.
pointer: rows keep their own targets; the container claims no clicks and wheel passes through; a click on a row moves the cursor and activates it.
keyboard: one roving Tab stop on the current row (the first reachable row with no cursor), and the cursor follows a row that takes the focus; arrows step along the orientation, Home and End jump, Return, Enter and Space activate, Tab leaves; the menu accepts `ShortcutOverride` for the keys it owns, so a window shortcut on an arrow does not outrank it; Home, End and Space stay with an editor inside a row; a row that already paints its own ring (`focused`) keeps the only one.
screen reader: the container is a `Grouping` named by `accessibleName`; rows name themselves and report selected.
size: rows stretch across the container on the cross axis. A vertical menu's natural width is the constant `Style.controlWidth` and long labels elide in their rows; a horizontal one is the sum of its rows' widths plus spacing and takes its height from the host (set when the menu is built, never switched afterwards). The main axis is unconstrained, so expanded entries never wrap into a second column. The menu does not clip, so a row's focus ring is not cropped; a ScrollArea in the owning composition bounds overflow and leaves the ring room.
tokens: space1, focus, indicatorWidth, opacityDisabled and band; rows bring their own type, icon and space scales.
motion: the thumb slides between rows in `Motion.micro` (a position animation is removed under reduced motion); rows settle their own state changes.
not designed: the row itself, popover placement or dismissal; use ListRow, Popover or the host for those.

expected: shell Workbench → Compositions → menu-items contains Wi-Fi secure/open networks, BLE devices, ON/OFF switches, volume/mute, plain/secondary actions and unavailable/report-only/structural rows. Up/down selects items even from editors; left/right/N/O adjusts volume; password typing remains text. Enter/Escape returns from volume to its own item. Pointer and row activation answer the same operation once. Local fixtures show connection progress, retry and outcomes without hardware or password persistence; reset cancels them. The provider's menu-items JSON hosts one native MenuInteractions fixture; it is not a component story or another production component type.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | transient shell actions, reviewed together in one composition | owner wants control interactions, not another selector in a row | Menu + existing controls | owner completes value/toggle/connect routes |
| ia/interaction | audio, Wi-Fi, Bluetooth groups; one cursor, one row route; up/down always navigates | owner's keyboard contract; Caelestia MenuItem separates intent; APG menu uses arrow stepping | Menu.step/activateCurrent, Slider/TextField key hook | actual repeated keys and pointer operations |
| hierarchy/token | compact editor beneath the text column, no duplicate Volume label or extra box | owner rejected detached slider; blueprint rhythm and hierarchy | ListRow.contentInset, Style.spaceTight/space2; existing type scale | owner judges association and reveal |
| responsive/state | one scrollable column; availability follows radios; pending/failure/retry; drafts retained until reset | hidden input must not activate; no lost work or fabricated production success | ScrollArea, Field, cancellable local fixture | keyboard into view, radio off, submit/retry/reset |
| polish | restrained common surface, motion only for disclosure/state | Quiet Luminous and reduced-motion law | Style.overlay/radiusLg, Motion.fast | owner review, no automatic audit |

Not designed: real network/audio services, production action-menu identity repair,
arbitrary nested menus, screen-reader speech verification or a JSON menu framework.
No new design tokens. APG's action-only menu is not an ARIA role claim for this
mixed-control native composition; each actual control keeps its own accessible name.

Measured (default theme, 1.25 scale, headless window): the thumb equals the cursor row's rectangle to the pixel at sm 32, md 40 and lg 56 (flow menu-pointer); Tab reaches the current row, arrows wrap past the disabled row, Home, End, Return and Space answer (flows menu-keyboard, menu-stepping); the ring is 2.4 px at a 2.4 px gap outside the thumb, 5.28:1 on the selected body; selected label 5.26:1, receded label 6.65:1, header 8.61:1; a row's hover zone measured from pixels is its rectangle, 364 by 40, with the 4 px gap dead; the menu-items composition answers the same Up, Down, Enter and Space from its editor as with the previous menu, plus Home.

Open: the menu writes the host-owned `currentIndex` and each row's `selected` (a host binding on either is replaced after the first move), and the pointer's hover lift and the cursor are two marks. Both are the owner's rulings (`docs/BACKLOG.md`); the unit mirrors the cursor and re-asserts its own through a `Binding`.
