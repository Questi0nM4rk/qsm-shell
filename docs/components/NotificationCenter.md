# NotificationCenter

A searchable history of notifications grouped by application; it filters, groups and navigates, and the host owns dismissal and consequence.
states: empty and list; live entries sort above archived within each application group; do-not-disturb rides an `IconButton` beside the search field; Clear history rides one beside the view switch and asks twice (`ArmedAction`: the first press arms in the danger colour, the second reports `clearRequested`; timeout, lost focus or the pointer leaving disarm it).
actions: `focusField`, `moveSelection`, `activateSelected`, `removeSelected` and `moveAction` share one keyboard route; hover, dismiss and action intents report upward and never resolve inside.
pointer: hover selects only while the pointer owns selection; rows keep their own targets and wheel scrolls the list.
keyboard: the search field holds focus and routes Up and Down to selection with `selectionClaimed`; accept activates and Escape reports outward; unclaimed keys report through one hook.
expected: entry-action navigation visits only enabled actions exposed by the selected NotificationCard; activation and dismissal call that card's functions, so archived, hidden, disabled and stale action targets cannot bypass its guards. No intent mutates the host's entries.
sorting: copy entries before sorting, group by application, live before archived and newest within each group; equal-recency groups retain feed order. Search includes the application name. Archive identity uses `archiveId` when supplied, with a legacy timestamp/content key otherwise. Dismissal reports the record to its host for removal; snapshot updates preserve delegates so hover/pause cannot recreate the hovered card.
sources: caelestia `StyledTextField.qml` supplies the focused search-field pattern, not notification routing or its host-side validation; Radix Toolbar supplies the keyboard-navigation reference. NotificationCard owns entry-action availability; the center adds search and a shared cursor rather than a second card policy.
screen reader: application sections label their groups; the search field, rows and actions name themselves; empty states announce no matches or nothing here.
size: list height follows content up to a maximum with a floor of two collapsed rows and their gap; fixed header, list and section spacing; the container follows its content.
tokens: space scale, iconMd, textMuted, danger, notificationCollapsedHeight, TextField, IconButton, ArmedAction, ListView, ScrollCue and EmptyState; `fadeColor` is required, the host states its ground; no local colours or measurements.
motion: none of its own; cards and cues settle their own changes.
not designed: live ephemeral display, swipe physics or dismissal itself; use NotificationStack, NotificationCard or the host for those.

## UIX audit

Evidence: source-reviewed. No capture, Workbench session, or run was started, and live geometry was not read. Runtime-exercised: none. Owner-accepted: none. Colour pairs are computed from the deep-night token hex values, not sampled from pixels. Tree-based geometry (`hyprctl`, the item-tree dump) was not available to this pass, so every size below is the arithmetic of the source tokens.

### Purpose and consequence

The task is to find a notification in the history by application or text, then read, expand, act on, or dismiss it without leaving the list. The component owns none of the consequences. `NotificationCenterSurface.qml` in qsm-desktop turns `activated` into `markRead`, `dismissRequested` into a service removal, and `clearRequested` into `clearArchive`.

### Controls and states

- Properties: `entries`, `dnd`, `view`, `query`, `maxListHeight` (`:26`), `swatchFor`, `fadeColor` (`:58`).
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

- Header: the search field is `TextField` md, `Style.size("TextField", "md")` = 40 (`tokens/deep-night.json`). Each `IconButton` is 40 = `controlHeight`, made of a 20 px glyph (`iconMd`) and 10 px padding on each side (`:294`).
- List height is `clamp(contentHeight, 64, maxListHeight)` (`:333-334`). The 64 is `Style.space6 * 2` (`space.6` = 32). The 420 is a property default.
- Long content: the list scrolls (ListView clip, `StopAtBounds`). A card preview clamps at `notificationPreviewHeight` 80 (card `:427`).
- Empty: `EmptyState` is centred in the list box (`:412-420`).
- Failure: none in this component.

### Visual roles and palette pairs

Computed from `tokens/deep-night.json`, WCAG 2.2 relative luminance:

| pair | ratio | use |
| --- | --- | --- |
| `text` #f0ecf5 on `surface` #42394c | 9.38 | card title (`textMd`) |
| `textMuted` #c5bad1 on `surface` | 5.89 | app name, body preview, timestamp (`textSm`, `textXs`) |
| `textMuted` on `band` #271e30 | 8.61 | section label (`textXs`, uppercase) |
| `accent` #d9b4ea on `band` | 8.87 | DND on glyph |
| `accent` on `surface` | 6.07 | unread dot |

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
- Popup corridor: not applicable. This component neither opens nor closes. The host's hover union and grace belong to `NotificationCenterSurface` and `EdgeScene`, and were not measured.

### Findings

Defects are source-backed. Status below is source-reviewed and load-checked (one offscreen capture of `notification-center`, exit 0, no QML error); none is owner-accepted.

- **nc-01 (major), OPEN (deferred, needs `NotificationCard.qml`): keyboard cannot mark an unread row seen.** `NotificationCenter.qml:216` (`activateSelected` falls to `toggleSelected`) never reaches `NotificationCard`'s `activated` (card `:595`, body click only). The AT press action runs only the primary action, so `markRead` never runs from the keyboard. The unread row stays in the Unread view and keeps the bell count. Fix: give the card an `activate()` that its body click and the centre's Enter both call. The owner decides whether Enter on an unread row marks it read, expands it, or both. This is the law "pointer, keyboard and programmatic routes call the same function".
- **nc-02 (major), the resting story shows the empty state.** *fixed (source-reviewed, load-checked): two live fixtures carry `read: false`, the archived one `read: true`; `view` is a unit control (Unread, All) synced both ways with the centre; the unit answers `activated` by marking the entry read.* `workbench/units/NotificationCenter.qml:18-46` has no `read` key on any entry. `view` defaults to `unread` (`:36`), so the filter at `:225-226` keeps nothing, and the empty state `All caught up` (`:416-417`) shows at rest. Fix: set `read: false` on one or two fixtures, and expose `view` as a unit control.
- **nc-03 (major), section labels are not padded.** *fixed (source-reviewed, load-checked): the section label is an `Item` that holds the card text column as `x` and `space2` as top inset.* `NotificationCenter.qml:362-370` sets `leftPadding` and `topPadding` on `Prose`, and `Prose.qml:38` is a plain `Text` with no padding property (grep for `Padding` in that file finds nothing). Qt drops the binding and reports it, so the label sits at x 0 instead of the app-name column at x 45 (the same 45 the card's headline uses). The arithmetic is 8 + 3 + 2 + 8 + 16 + 8 = 45 on both sides; the unlabelled Qt report is unverified because nothing was run. Fix: wrap the `Prose` in an `Item` that holds the padding, or set `anchors.leftMargin` on the label.
- **nc-04 (major), Clear history is instant, irreversible, and sits 8 px from DND.** *fixed (source-reviewed, load-checked): Clear moved to the view row, away from DND, and runs through `ArmedAction`; armed shows `Style.danger` and the name `Confirm clear history`. The host still runs `clearArchive` on `clearRequested`.* The trash `IconButton` (`:300-305`) is the same 40x40 target as DND, with the same glyph colour (`Style.text`) and no danger cue. The desktop answers `clearRequested` with `clearArchive()` at once (`NotificationCenterSurface.qml`, `onClearRequested`), and no undo exists in the source. Fix: route Clear through the library's `ArmedAction` (`Components/ArmedAction.qml`, not read here) so a second press confirms, and move it away from the toggle. The host still runs `clearArchive`.
- **nc-05 (minor), the scroll fade defaults to the wrong ground.** *fixed (source-reviewed, load-checked): `fadeColor` is `required`; the unit sets `Style.band`. Callers must now state it (the desktop already passes `Theme.band`).* `NotificationCenter.qml:50-58` says the fade "MUST come from the consumer", then sets `property color fadeColor: Style.surface`. The unit draws on `Style.band` (`:48`) and never sets `fadeColor`, so any overflow in the unit fades a surface-coloured strip over band (a 1.46:1 step from the tokens). The desktop passes `Theme.band`. The fixture does not overflow today, so this is latent. Fix: make `fadeColor` `required` and have the unit set `Style.band`.
- **nc-06 (minor), search matches the word "undefined".** *fixed (source-reviewed, load-checked): the search text uses `entry.body ?? ""`.* `NotificationCenter.qml:230` builds the search text with `${entry.body}`. The card treats `body` as optional (`entry.body ?? ""`), so an entry without a body is searched as `undefined`. Typing "undefined" lists entries with no body. Fix: `${entry.body ?? ""}`.
- **nc-07 (minor), the list floor does not match its comment or the record.** *fixed (source-reviewed, load-checked): the floor is `notificationCollapsedHeight * 2 + space2` (80 at the default tokens); the comment and this record agree.* `:24-25` and the record's `size:` line say the floor is "two rows' worth". The code at `:333` floors at 64 px. Two collapsed rows with the 8 px gap are 36 + 8 + 36 = 80 px, and a row with body text is taller still. One notification therefore leaves 28 px of empty box under it. Fix: compute the floor from `notificationCollapsedHeight` and `space2`, or correct the comment and the record.
- **nc-08 (minor), the workbench unit is taller than its story window.** *fixed (source-reviewed, load-checked): the unit is `Style.controlWidth` (380) tall, inside the 500 px story viewport; not measured in the live window.* `workbench/units/NotificationCenter.qml:49-50` sets `implicitHeight: Style.controlWidth * 2` (760). `workbench/stories.json:1032-1035` declares a 500 px viewport. If the harness uses that viewport as the window, the lower 260 px of the list is cut off. Not run, so unverified against the harness.
- **nc-09 (minor), the unit cannot reach action navigation.** *fixed (source-reviewed, load-checked): `runAction` and `integration.actions` gain `move-action-next`, `move-action-previous` and `focus-field`.* The record's `actions:` line names `moveAction` and `focusField`. The unit's `runAction` (`:121-128`) lacks both, so Tab through a card's actions cannot be driven in the workbench.

Source conflicts (the owner decides which wins):

- AGENTS.md "Definition of done" item 6 says every number comes from `Style` or `Motion`. The component law on property defaults says a call site passes a different value and the library keeps one default. `maxListHeight: 420` (`:26`) fits the second law and breaks the first. A `Style` token would make the fix shared.
- The record's `actions:` and `size:` lines say two-row floor and Capsule controls. The code uses 64 px (`:333`) and `IconButton` (`:290`, `:300`). The record was not updated when the code changed.
- The `fadeColor` comment (`:50-57`) forbids a default, and the line after it (`:58`) sets one.

Proposals (taste, not defects):

- The DND on-state changes only the glyph's hue (`:293`), with the same moon glyph. Give the on-state a shape change, or a `Style.tone` selected state. Whether colour alone breaks 1.4.1 is a11y-audit's call.
- Shared, outside this component: the three neutral steps in `deep-night` measure 1.46:1 between `surface` and `band` from the token hex values. AGENTS.md states 1.30:1 per step. The tokens file is shared, so the owner decides which number the ladder follows.

Hypotheses (observed in the arithmetic, not measured):

- H1: the empty state (an icon of 24, a 14 px title line, an 8 px gap, and a 12 px body line, about 70 to 75 px in total) is taller than the 64 px floor (`:333`). It would overflow by a few pixels on each side if a host sized the panel to content. Both current hosts give the centre a fixed height, so this is not reached. The line heights are unverified.
- H2: the section label and card text align at 45 px only while `SelectionMark` is 5 px wide when `strong` (`markThickness + spaceTight`). A change to the tick width moves every label against its card.
- H3: the DND on-state reads at 8.87:1, computed. Its rendered pixel is not sampled.

Not examined: rendered pixels and any capture; the Segmented badge colour and track; the search placeholder contrast; dark, high-contrast, and scale variants (only deep-night tokens were read); keyboard keys beyond Up, Down, Enter, Tab and Delete; the accessibility tree; a real pointer; the desktop rollout geometry; `ArmedAction`'s API.
