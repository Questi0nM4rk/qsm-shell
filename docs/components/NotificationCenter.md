# NotificationCenter

A searchable history of notifications grouped by application; it filters, groups and navigates, and the host owns dismissal and consequence.
states: empty and list; live entries sort above archived within each application group; the search field takes the whole first row (a menu that rolls out of a screen corner opens under the pointer, and a field is the one control a click there cannot harm); do-not-disturb and Clear history ride `IconButton`s beside the view switch, and Clear asks twice (`ArmedAction`: the first press arms in the danger colour, the second reports `clearRequested`; timeout, lost focus or the pointer leaving disarm it).
actions: `focusField(fromPointer)` (a pointer-opened menu puts the caret in the field without the keyboard ring), `moveSelection`, `activateSelected`, `removeSelected` and `moveAction` share one keyboard route; hover, dismiss and action intents report upward and never resolve inside.
pointer: hover selects only while the pointer owns selection; rows keep their own targets and wheel scrolls the list.
keyboard: the search field holds focus and routes Up and Down to selection with `selectionClaimed`; accept activates and Escape reports outward; unclaimed keys report through one hook.
expected: entry-action navigation visits only enabled actions exposed by the selected NotificationCard; activation and dismissal call that card's functions, so archived, hidden, disabled and stale action targets cannot bypass its guards. No intent mutates the host's entries.
sorting: copy entries before sorting, group by application, live before archived and newest within each group; equal-recency groups retain feed order. Search includes the application name. Archive identity uses `archiveId` when supplied, with a legacy timestamp/content key otherwise. Dismissal reports the record to its host for removal; snapshot updates preserve delegates so hover/pause cannot recreate the hovered card.
sources: caelestia `StyledTextField.qml` supplies the focused search-field pattern, not notification routing or its host-side validation; Radix Toolbar supplies the keyboard-navigation reference. NotificationCard owns entry-action availability; the center adds search and a shared cursor rather than a second card policy.
screen reader: application sections label their groups; the search field, rows and actions name themselves; empty states announce no matches or nothing here.
size: list height follows content up to a maximum with a floor of two collapsed rows and their gap; fixed header, list and section spacing; the container follows its content.
scroll: the list's `ScrollCue` draws the edge fade only; the fade says there is more, a mark beside it said so a second time.
tokens: space scale, iconMd, textMuted, danger, notificationCollapsedHeight, TextField, IconButton, ArmedAction, ListView, ScrollCue and EmptyState; `fadeColor` is required, the host states its ground; no local colours or measurements.
motion: none of its own; cards and cues settle their own changes.
not designed: live ephemeral display, swipe physics or dismissal itself; use NotificationStack, NotificationCard or the host for those.

## UIX audit

Evidence: source-reviewed. No capture, Workbench session, or run was started, and live geometry was not read. Runtime-exercised: none. Owner-accepted: none. Colour pairs are computed from the deep-night token hex values, not sampled from pixels. Tree-based geometry (`hyprctl`, the item-tree dump) was not available to this pass, so every size below is the arithmetic of the source tokens.

### Purpose and consequence

The task is to find a notification in the history by application or text, then read, expand, act on, or dismiss it without leaving the list. The component owns none of the consequences. The host turns `activated` into marking read, `dismissRequested` into a removal, and `clearRequested` into clearing the archive.

### Controls and states

- Properties: `entries`, `dnd`, `view`, `query`, `maxListHeight` (`:26`), `swatchFor`, `fadeColor` (required).
- Signals: `dismissRequested`, `activated`, `actionTriggered`, `hoverChanged`, `dndToggled`, `clearRequested`, `escaped`, `selectionClaimed`, `keyPressed`.
- Functions: `focusField`, `beginVisit`, `moveSelection`, `toggleSelected`, `removeSelected`, `moveAction`, `activateSelected`.
- Implemented: the Unread and All views, the three empty states (`All caught up`, `Nothing here`, `No matches`), search, app grouping, cursor restore, DND on and off (glyph colour changes only).
- Not a state of this component: loading and failure belong to the host. There is no cancel path for `removeSelected`, which is instant.

### Routes

- Pointer: hovering a row moves the cursor when `Interaction.pointerSelects` (`:404-408`). A click on the leading column toggles expansion (card `:611`, then `:385-389`). A click on the body of an unread row fires `activated` (card `:594-595`). DND and Clear are `IconButton` StateLayers.
- Wheel: the ListView takes the wheel. Hover does not expand a row (`expandOnHover: false`, `:384`). `ScrollCue` sets `enabled: false`, so it never takes input.
- Keyboard: the search field holds focus (`:269`). Up and Down move the cursor (`:277-281`). Enter runs `activateSelected` (`:283`, `:205-218`): it runs the focused card action if one is set, otherwise it toggles expansion. Tab and Delete are the host's, through `keyPressed`. Escape reports `escaped`. Nothing on the keyboard route fires `activated` (see nc-01).
- Focus: `IconButton` takes `StrongFocus`. The list cursor is shown as the selected tint of a bodied card.
- Accessible names: `Notification views` (Segmented `:316`), `Do not disturb` with `Accessible.checkable` and `checked` (`:292-296`), `Clear history` (`:302`). Section labels declare no role. Keyboard, focus and screen-reader criteria are a11y-audit's and are not ruled here.

### Sizes, empty, long, failure

- Header: the search field is `TextField` md, `Style.size("TextField", "md")` = 40 (`tokens/deep-night.json`). Each `IconButton` is `size: "md"`: a 40 px box with a 20 px glyph and 10 px padding on each side.
- List height is `clamp(contentHeight, floor, maxListHeight)`. The floor is `notificationCollapsedHeight * 2 + space2` (80 at the default tokens), two collapsed rows. The 420 is a property default.
- Long content: the list scrolls (ListView clip, `StopAtBounds`). A card preview clamps at `notificationPreviewHeight` 80 (card `:427`).
- Empty: `EmptyState` is centred in the list box (`:412-420`).
- Failure: none in this component.

### Visual roles and palette pairs

Computed from `tokens/deep-night.json`, WCAG 2.2 relative luminance:

| pair | ratio | use |
| --- | --- | --- |
| `text` #f0ecf5 on `surface` #3b3145 | 10.53 | card title (`textMd`) |
| `textMuted` #c5bad1 on `surface` | 6.61 | app name, body preview, timestamp (`textSm`, `textXs`) |
| `textMuted` on `band` #271e30 | 8.61 | section label (`textXs`, uppercase) |
| `accent` #d9b4ea on `band` | 8.87 | DND on glyph |
| `accent` on `surface` | 6.82 | unread dot |

Spacing: `space2` (8) between cards and between header controls, `space3` (12) between header, Segmented and list. Cards are bodied surfaces (`:383`). Section labels use `Prose` role `section`.

### Motion

The component has no motion of its own. The card height `Behavior` (`Motion.fast`, emphasized) and the `ScrollCue` opacity (`Motion.medium`) belong to those types. `review-animations` was not loaded because this component does not animate. Reduced motion is handled in this component by `shadowReach` (`:82`), which drops to 0 under `Style.reducedEffects`.

### Pointer geometry

Model: one-dimensional Fitts in Shannon form, ID = log2(1 + D/W). W is the target's extent along the approach axis. D and the origins are modelled from source geometry, not measured. No human average is claimed. The weights are equal across targets, which is an assumption.

| target | input shape | painted | W | D | ID (bits) | landing tolerance, neighbour |
| --- | --- | --- | --- | --- | --- | --- |
| DND | 40x40, StateLayer over the `IconButton` | 20 px glyph | 40 | 150 px from search field centre (assumed) | 2.25 | ±20 px; 8 px gap to Clear |
| Clear | 40x40 | 20 px glyph | 40 | 48 px from DND centre (40 + 8 gap, derived) | 1.14 | ±20 px; 8 px gap to DND |
| row body, no body text | the card rectangle, clickable only when activatable | 36 px headline | 36 vertical | 44 px pitch (36 + 8) | 1.15 | ±18 px; 8 px gap to next row |
| leading column (expand) | 0 to 45 px wide, full row height | 16 px glyph at x 21 | 45 horizontal | 151.5 px, body centre to leading column (unit width 348 assumed) | 2.13 | ±22 px; body beyond it is the activation zone |

- Input against painted: the card's shadow (`cardShadowExtent` 12) is painted outside the body and is not input.
- Segmented: not computed, its track geometry was not read.
- Popup corridor: not applicable. This component neither opens nor closes. The host's hover union and grace were not measured.

### Findings

Defects are source-backed. Status is source-reviewed; none is owner-accepted.

- **nc-01 (major), OPEN (deferred, needs `NotificationCard.qml`): keyboard cannot mark an unread row seen.** `NotificationCenter.qml:216` (`activateSelected` falls to `toggleSelected`) never reaches `NotificationCard`'s `activated` (card `:595`, body click only). The AT press action runs only the primary action, so `markRead` never runs from the keyboard. The unread row stays in the Unread view and keeps the bell count. Fix: give the card an `activate()` that its body click and the centre's Enter both call. The owner decides whether Enter on an unread row marks it read, expands it, or both. This is the law "pointer, keyboard and programmatic routes call the same function".

Source conflicts (the owner decides which wins):

- AGENTS.md "Definition of done" item 6 says every number comes from `Style` or `Motion`. The component law on property defaults says a call site passes a different value and the library keeps one default. `maxListHeight: 420` (`:26`) fits the second law and breaks the first. A `Style` token would make the fix shared.

Proposals (taste, not defects):

- The DND on-state changes only the glyph's hue (`:293`), with the same moon glyph. Give the on-state a shape change, or a `Style.tone` selected state. Whether colour alone breaks 1.4.1 is a11y-audit's call.

Hypotheses (observed in the arithmetic, not measured):

- H1: the section label and card text align at 45 px only while `SelectionMark` is 5 px wide when `strong` (`markThickness + spaceTight`). A change to the tick width moves every label against its card.
- H2: the DND on-state reads at 8.87:1, computed. Its rendered pixel is not sampled.

Not examined: rendered pixels and any capture; the Segmented badge colour and track; the search placeholder contrast; dark, high-contrast, and scale variants (only deep-night tokens were read); keyboard keys beyond Up, Down, Enter, Tab and Delete; the accessibility tree; a real pointer; a host's rollout geometry; `ArmedAction`'s API.
