# NotificationCard

A person receiving a transient notification can read its source, headline and message, then open the source's current default action or dismiss the notice. The host owns the record, availability and every consequence.

`bodied` is the opt-in row material: a `surface` body of `bodyRadius` with a slight shadow. The default stays boxless. Menu entries and popup entries both use it.

| layer | decision | why / source | token or pattern | owner-review evidence, when prepared |
| --- | --- | --- | --- | --- |
| posture | Brief, non-modal feedback; arrival never steals focus | Existing popup purpose; notification spec | Existing rollout / capsule hosts | Arrival leaves the foreground application usable |
| task | Read the actual notification, then optionally open its supplied destination | Production-actions spec: useful message before action | App identity + summary + body | Body is visible without hover |
| ia | Keep app identity and summary first; show a two-line body preview beneath them | Client fields are the only trustworthy context | Existing icon slot; `Prose` roles | Missing body shows no invented copy |
| interaction | One listed `activatePrimary()` reports intent only when the host says the current default exists; dismissal stays separate | Shared action route prevents pointer/key divergence and guessing a named action | `StateLayer`, `T.Action`, `primaryActionEnabled`, `primaryTriggered` | Body tap, Enter, Space, accessibility and caller use the same function; absent/retiring actions do nothing |
| hierarchy | Preserve urgency and source identity; caller may opt into a surface body | Owner's reference-led containment choice; reusable transparent default | `bodied`, `bodyRadius`, `Surface`; existing text roles | Body contains source, time and preview without implying a new action or read state |
| token | Size the preview to its real lines with `notificationPreviewHeight` as the ceiling, and give the expanded body a bounded viewport | Existing 36px token is headline-only; the new composition needs room while stack growth stays bounded | `Style.notificationPreviewHeight`, `Style.notificationBodyViewportHeight`; notification width and existing spacing/type scales | A one-line message is shorter than a two-line one, and none exceeds the ceiling; full content scrolls inside the expanded bound |
| responsive | Keep width fixed; wrap body text and scroll only the expanded long body | Popup/capsule have fixed shell width and clipped host geometry | `Style.notificationWidth`; `Flickable` viewport | Full text stays inside both host bodies |
| state | Preserve hover, press, focus and disabled through `StateLayer`; input withdrawal preserves paint and immediately refuses actions | Component laws and stack retirement contract | `StateLayer`, `inputEnabled`, `Style.disabled` | Press is visible without changing row geometry; disabled cards dim semantic text/glyph colours, while informational no-default rows retain full strength |
| polish | Keep current entrance, expansion and swipe movement; the body is the card's own, with no separate lifetime | One body per row, no duplicate policy or movement | Existing `Motion` and stack clip | The shadow room participates in retained extent; input withdrawal never collapses or dims the frozen picture |

states: collapsed preview and expanded full body; hover still reports/expands, drag still arbitrates swipe, pause and frozen-retirement behavior stay host-owned. Urgency is the app glyph's colour alone (critical `danger`, normal `info`, low `textMuted`; spec 04); the accent tick is only the list cursor (`selected`) on a boxless card.
actions: `dismiss()`, existing `activateAction(id)`, and `activatePrimary()` share their native, keyboard/accessibility and programmatic routes. Popup mode hides named actions; only exact host-enabled default is primary. The card never calls a service, mutates `entry`, or dismisses itself for primary activation.
pointer: `StateLayer` owns the sole left-tap route and hand cursor when primary is available; its drag-threshold tap is cancelled by a swipe, middle-click dismisses, expanded vertical body scrolling does not also expand the card, horizontal dismissal remains available, and wheel not consumed by the viewport passes through. The primary summary exposes pressed feedback without scaling the card or changing fullscreen geometry.
keyboard: the card offers a tab stop and Enter/Space route only when primary is available and its host grants keyboard focus; it never focuses itself on arrival. A host that gives a popup window no keyboard focus leaves it without a native keyboard route, and no popup key reachability is claimed. Action-row index behavior remains for center consumers.
screen reader: button role/name only when primary is available; otherwise source, summary and body remain readable text. Body action has a clear accessible name; existing named actions retain their own names.
size: fixed `Style.notificationWidth`; collapsed natural size uses `Style.notificationPreviewHeight`; expanded height is bounded by `Style.notificationBodyViewportHeight` plus existing details. A bodied card adds `shadowRoom` under its body and includes it before height is frozen. Body text wraps and scrolls, never grows the stack without bound. Source identity is capped to a Style-derived share of the header so summary keeps room; timestamp sits quietly in that same header. `bodied` defaults false, so existing callers keep their composition; `bodyRadius` defaults to the large radius.
tokens: notification width, header height, preview height, body viewport height, iconSm, body radius, shadow tokens, space scale, urgency/text roles and Motion. No local colors or measurements. Material does not decide host background, lifetime or dismissal.
motion: existing entrance, expansion, swipe, freeze and reduced-motion behavior only. Body preview does not add another height animation or alter host/render geometry ownership.
expected: the same `activatePrimary()` is the only primary route and reports `primaryTriggered` only when enabled, visible and input-ready. A missing, stale or disabled default never becomes a first-named-action fallback. Long body is fully readable in the bounded expanded viewport; live relative time refreshes at minute intervals. Keyboard action requires a focus-capable host and is not reachable through the current passive production popup. Component reports intent and host owns effects.
not designed: notification lifetime, protocol lookup, application focus/open confirmation, history, grouping, popup dismissal policy or new shell host geometry. Owner judgment of the prepared composition remains pending.

## UIX audit

Evidence: **source-reviewed** for every row. No runtime-exercised or owner-accepted evidence exists for this type.
Channels available: source only. The capture and live-geometry channels were not reached, because no session was started under this audit. Design source: `tokens/deep-night.json`, the surface ladder and component laws in `AGENTS.md`, and this record. The repository has no `design/` directory, so there is no per-page override. Only the deep-night token set was read. Contrast rows are token hex values, not rendered pixels. Geometry rows are arithmetic on token values, not measurements.

### Consumers

- `NotificationStack.qml:416`: popup. Uses the default `expandOnHover: true`, `showActions: false`, `verticalDragEnabled: inputEnabled` (line 431).
- `NotificationCenter.qml:372`: list. `bodied: true`, `expandOnHover: false`, `showActions` left at its default, `hostExpanded` bound to the host's expanded key.
- Caelestia sibling: `components/controls/` has no notification type. The closest is `modules/sidebar/Notif.qml`, used for the comparison in proposals.

### Expected controls and states

| state | expected | implemented | source |
| --- | --- | --- | --- |
| rest | text, app glyph or image, timestamp | yes | 214-265, 351-417 |
| hover | popup: expansion; list: bodied lift | yes; the boxless list has no hover change (see P8) | 91, 299 |
| press | colour change on the body | title colour only; bodied body via `Surface.pressed` | 406-407, 300 |
| focus | keyboard ring, outside the body | yes, `StateLayer` ring driven by `activeFocus` (F1 fixed) | 614 |
| disabled | colour dimmed through `Style.disabled` | yes | 392, 406, 438, 496 |
| selected | list tick (boxless) or body (bodied) | yes | 324-332, 301 |
| unread | accent dot | yes; not in the accessible name (H3) | 394-401 |
| empty body | collapsed height, no detail | yes | 252-261 |
| long body | two-line preview; popup scrolls the expanded body | yes | 444, 470-472, 475-521 |
| archived | time shows `archivedAt`; no action row | yes | 92, 232, 525 |
| image or swatch failure | visible fallback | yes, the glyph stays until the image is ready (F4 fixed) | 359-374 |

Public controls: `entry` (required), `alwaysExpanded`, `draggable`, `inputEnabled`, `primaryActionEnabled`, `showActions`, `bodied`, `bodyRadius`, `expandOnHover`, `unread`, `activatable`, `selected`, `actionFocusIndex`, `hostExpanded`, `swatch`, `animateEntrance`. Actions: `activatePrimary()`, `dismiss()`, `activateAction(id)`. Signals: `dismissed`, `expandRequested`, `actionTriggered`, `primaryTriggered`, `activated`. The unit exercises only default-action, body, record and input. It does not show `showActions`, `bodied`, `selected`, `unread`, `swatch` or the list expansion.

### Routes

- **Pointer.** Body tap runs `activatePrimary()` when primary is available (`layer`, 580-596), and `activated` runs for an unread center row (595). A leading-column click emits `expandRequested` in list mode only (601-612). Middle click dismisses (626-630). A horizontal swipe past 40% of width dismisses (642-672). A vertical drag past 20 px sets the card's internal drag expansion (664-666). The wheel over an expanded body scrolls it and passes through at either end (507-520).
- **Keyboard.** Tab stop when primary is available (614). Enter and Space run `activatePrimary()` (616-624). There are no arrow keys and no dismiss key. The focus ring follows `activeFocus` (F1 fixed). Action-row focus belongs to the list host (75, 542-550).
- **Accessibility.** Primary available: role Button, name `label: summary` (112-115). Otherwise: StaticText, name `app: summary`. Description is the body (116). AT press runs `activatePrimary()` (117). Action labels are Buttons (544-546). The metadata description is the absolute time (414-415).
- **Route equivalence.** Body tap (586-593), Enter and Space (616-624), and AT press (117) all call `activatePrimary()`, which checks `enabled`, `visible`, `inputEnabled` and `primaryActionAvailable` before reporting (178-183). Confirmed in source.

### Sizes, empty, long, failure, cancellation

- Width is 380 (`Style.notificationWidth`, token `geometry.notificationWidth`). The center overrides it with a list-width binding.
- Heights from token arithmetic: no body 36; one-line preview 68; two-line preview 80 (the cap; see F3); expanded `36 + 4 + min(content, 96) + 8`, giving 68 for one line, 88 for two, 108 for three, 128 for four, and 144 from five lines, where the popup scrolls inside 96 px.
- Lead column is 45 px (`headline.x + 24`, with `headline.x` = 21). The tick reserves 5 px even when hidden (`SelectionMark.qml:34`).
- Summary is NoWrap with ElideRight (`Prose` title role). App name is capped to `(380 - 16 - 36) / 3` = 109 px (line 391) and elides.
- Long body wraps and elides in the preview. Long expanded body is an unknown line count (H2).
- Failure: a missing or undecodable image leaves an empty box (F4). An image or swatch removes the urgency glyph (F2).
- Cancellation: `freezePresentation` holds height and entrance progress during retirement (151-161). A swipe below 40% springs back (638).

### Visual roles and palette pairs (token values)

| pair | ratio | target | verdict |
| --- | --- | --- | --- |
| body `textMuted` #c5bad1 on `band` #271e30 | 8.61 | 4.5 (1.4.3) | pass |
| body `textMuted` on `surface` #3b3145 | 6.61 | 4.5 | pass |
| title `text` #f0ecf5 on `surface` | 10.53 | 4.5 | pass |
| action or unread `accent` #d9b4ea on `band` | 8.87 | 4.5 | pass |
| `info` glyph #89cff1 on `band` | 9.32 | 3 (1.4.11) | pass |
| `danger` glyph #f5aeb7 on `band` | 8.84 | 3 | pass |
| low-urgency glyph `textMuted` on `band` | 8.61 | 3 | pass |
| disabled text: `textMuted` blended 0.35 to `band` (#5e5568) on `band` | 2.26 | exempt (inactive) | dims by design |

Focus ring: no colour, no pair, not drawn (F1). The swatch border is `textMuted` on an entry-supplied fill, so no pair can be computed.

### Motion and reduced motion

Values come from the `Motion` singleton; reduced values are from `Motion.qml`. The easing ruling belongs to review-animations.

| what | source | normal | reduced |
| --- | --- | --- | --- |
| entrance opacity and scale 0.97 to 1 | 271-281 (`microPop`, `microPopScale` 0.97) | 120 ms, emphasized | 60 ms; scale still runs (H5) |
| expansion height | 283-290 (`fast`) | 180 ms, emphasized | 80 ms |
| preview and details crossfade | 433-435, 463-465 (`fast`) | 180 ms | 80 ms |
| swipe spring-back | 634-639 (`fast`) | 180 ms, standard | 80 ms (H4) |
| press | no motion, colour only | - | - |

### Pointer geometry

Input versus painted size:

| element | input shape | painted shape | origin |
| --- | --- | --- | --- |
| card: primary tap, middle-click dismiss, hover expansion | 380 x H, the card rectangle (`StateLayer` with `target: null`) | bodied: the same rectangle; boxless: text only | 580-596, 626-630 |
| leading column | 45 x H, x 0 to 45 | 16 x 16 glyph at x 21 to 37 | 601-612, 351-382 |
| action label (center only) | label box plus 5 px each side (`anchors.margins: -5`) | 12 px text | 547-559 |
| swipe dismiss | 152 px horizontal travel (0.4 x 380) | none | 652-669 |

Origin assumptions, all from source arithmetic, none measured: the leading column ends at x 45; the text column starts at x 45 (`bodyPreview` and `details` left at `headline.x + 24`, 422-423, 452-453); the headline right edge is at x 368; the glyph is vertically centred in the 36 px header.

Label origins and weights (assumed from roles, not rendered): app name Regular 12 px (supporting role); title Bold 14 px (`textMd`, bold role); timestamp Regular 10 px in the monospace face (metadata role, `technical: true`); body Regular 12 px (a plain `Text` with no weight set).

Fitts difficulty. Width model: nominal width along the approach axis, with no effective-width correction. ID = log2(1 + D/W).

| target | W (px) | D (px) | ID (bits) | landing tolerance (plus or minus W/2) |
| --- | --- | --- | --- | --- |
| leading column, from card centre (190, H/2) to column centre x 22.5 | 45 | 167.5 (measured from the card's own geometry) | 2.24 | 22.5 px |
| card from outside, vertical approach, one-line rest | 68 | 200 (assumed; the host owns the distance) | 1.98 | 34 px |
| card from outside, two-line rest | 80 | 200 (assumed) | 1.81 | 40 px |
| card, expanded at its maximum | 144 | 200 (assumed) | 1.26 | 72 px |

Neighbouring interference: the stack's `rowSpacing` defaults to 0 (`NotificationStack.qml`), so adjacent cards abut. An overshoot past one card's edge lands on its neighbour. Hover expansion grows the card's bottom edge by up to 64 px (144 minus 80), so a pointer resting near the bottom edge is pushed off the card. Popup corridor: this card has no trigger corridor and no entry delay (expansion is the `expanded` binding at line 91, with no timer). Keep-open after leaving belongs to the host's rollout, not this card.

### Findings

Defects (source-backed, with file and line, and what a person sees):

- **F1, major, line 614.** **Fixed (source-reviewed, load-checked).** the card's `StateLayer` takes `focused: root.activeFocus` and `focusRadius`, so the shared ring draws outside the body on Tab. Original finding: The card takes a Tab stop when primary is available, but it draws no focus indicator. `StateLayer.qml:72` reads `(root.parent as T.Control)?.visualFocus`, which is null for this card's layer, so `layer.focused` stays false. A person who Tabs to a card sees nothing change, and Enter then runs an invisible action. Fix: draw a keyboard ring outside the body from `root.activeFocus`, using a `Style` focus token, with the gap at `Style.spaceTight`. The WCAG 2.4.7 verdict belongs to a11y-audit. Shared: false.
- **F2, major, lines 359-382 and 205-212.** **Fixed (source-reviewed, load-checked).** an image or swatch slot with critical or low urgency shows the urgency glyph as an `iconXs` badge on its corner. Original finding: When the entry carries a swatch or an image, the urgency glyph is hidden (376-382 require no swatch and no image). Neither the swatch nor the image carries urgency. A critical and a normal notification from one app with an icon look the same. The record's hierarchy row says urgency is preserved. Fix: when the slot shows an image or swatch and urgency is not normal, draw the urgency glyph as a badge at the slot's corner, using the existing `Style.iconXs` (`Style.qml:219`). Shared: false.
- **F3, minor, lines 256-257 with `tokens/deep-night.json:101`.** The preview cap is `notificationPreviewHeight` 80. A two-line body needs `36 + 4 + 40 + 8` = 88. So a two-line card has no bottom inset (text ends at y 80, the card bottom), while a one-line card has 8 px (68 px tall). On hover, a two-line card grows from 80 to 88 px with no new text (expanded height at 258-259). Fix: set the token to 88, which is headline 36 plus `space1` 4 plus two lines of 20 plus `space2` 8. Shared: true (`tokens/*`).
- **F4, minor, lines 368-374.** **Fixed (source-reviewed, load-checked).** the image shows only at `Image.Ready`; otherwise the urgency glyph shows. Original finding: The `Image` has no `status` check. Its visibility (370) is true whenever `imagePath` is non-empty, and the glyph (378) needs an empty `imagePath`. A missing or undecodable file therefore leaves an empty 16 px box in the header, and the urgency glyph is gone too. Fix: show the image only when `status === Image.Ready`, and show the glyph otherwise. Shared: false.
- **F5, minor, line 473 (the BACKLOG residual lint item).** **Fixed (source-reviewed, load-checked).** the explicit height is removed; the layout sizes the child from `implicitHeight`. Original finding: `bodyViewportHost` sets `height: implicitHeight` while it is a direct child of the `ColumnLayout` `details` (450), and it also sets `Layout.fillWidth` (469). The explicit height overrides the layout's own sizing of the child, which is the rule in qml-ui. Lint confirmation: `/usr/lib/qt6/bin/qmllint -I qml` exits 0 with no output on this file, so the item is not reproduced by that run. The breach is confirmed in source only. A person sees nothing wrong at current values. Fix: delete line 473, because the layout sizes the child from `implicitHeight`. Shared: false.
- **F6, minor, lines 647 and 91, with `NotificationStack.qml:431`.** **Fixed (source-reviewed, load-checked).** the Y axis no longer depends on `expanded`, so hover cannot disable it; a vertical drag in a popup now sets the internal drag expansion. A touch drag on the body viewport may also reach it; not verified live. Original finding: The stack passes `verticalDragEnabled: true`, but `yAxis.enabled` is `verticalDragEnabled && !expanded` (647). In popup mode, hover makes `expanded` true (91), and a press on a hovered card happens while hovered. So the Y axis is disabled before the drag starts, and vertical drag-to-expand never runs. A person pulling a popup card down gets only the hover expansion. Fix: delete `verticalDragEnabled` from the stack and the drag-expansion path, or make the Y axis independent of hover. Shared: false.
- **F7, minor and latent, lines 77 and 664-666, with `NotificationCenter.qml:380`.** **Fixed (source-reviewed, load-checked).** `dragExpanded` is now the internal `_dragExpanded`; the host binds `hostExpanded`, and `NotificationCenter.qml` follows. Original finding: `dragExpanded` is documented as drag-only, and the card writes it on a vertical drag (666). The center binds it to its own click-expanded key (380). Once a drag writes the property, the binding is replaced, and the host loses control of that card's expansion. Nothing shows this today, because the center does not enable vertical drag. Fix: keep `dragExpanded` internal and give the host its own property, such as `hostExpanded`. Shared: false.

Redesign proposals (taste or laws, no measured defect):

- **P1.** Dismissal has no visible control. The only routes are middle-click (626-630) and a 152 px swipe (652-669). ux-audit check 5 decides whether a close target is needed. The card would emit `dismissed` only, because the host keeps dismissal policy.
- **P2.** Hover expansion moves the stack under the pointer by up to 64 px. Owner decision: a fixed rest height with click or key expansion, or keep hover expansion.
- **P3.** Caelestia `modules/sidebar/Notif.qml` shows a one-line compact body beside the summary, with the full body only when expanded, and the time only then. A one-line preview removes the geometry of F3 and reduces density. Taste.
- **P4.** Caelestia tints the whole container for critical notifications (`secondaryContainer`), so urgency survives any icon. That is an option for F2.
- **P5.** Numbers in the component, against the law "every number comes from Style or Motion": `dividerStrength` 0.25 (226) belongs in `Style`; the timer `60 * 1000` (215) and the time arithmetic (238-245) need a named constant or a `Style` value; `previewLines` 2 (225) follows the token set. `swatchBorder` 1 (227) is a device pixel, which the comment justifies.
- **P6.** The comment at line 554 says the action label is 14 px. `Style.textSm` is 12 px (`tokens` `typeSm` 12). The 24 px hit target (a 12 px line plus 10 px) is an estimate, because font metrics are unmeasured. Fix the comment.
- **P7.** `Image` has no `sourceSize`, so an app icon decodes at full size (qml-ui cost rule).
- **P8.** Boxless list mode (`expandOnHover: false`, `bodied: false`) has no hover change, because the lift applies only when bodied (299). No current consumer uses it, so this is latent.
- **P9.** The card's `Accessible.name` (113-115) omits the unread state. a11y-audit should read the tree.

Source conflicts (which one decides is the owner's ruling; the code decides for now):

- **S1.** This record's size row says a bodied card "adds `shadowRoom` under its body and includes it before height is frozen". The code has no `shadowRoom` (no match in the file). `implicitHeight` is `restHeight` (251, 258-261). The center applies its shadow reach as a width inset instead. Either the record changes or the code adds shadow room.
- **S2.** The keyboard row says the Tab stop is offered "only when ... its host grants keyboard focus". The code gates `activeFocusOnTab` on `primaryActionAvailable` alone (614), and the card has no host grant.
- **S3.** The glyph paragraph and the comment at 208-209 say urgency is "the glyph's colour alone". The icon name also changes shape with urgency (205-207: alert-triangle, bell, moon). For the glyph case the record is wrong; for the image case F2 applies.
- **S4.** The hierarchy row says urgency is preserved, which F2 contradicts.

Hypotheses (not measured, never part of the table):

- **H1.** A bodied card's shadow may be clipped to the body's bounds, because the `layer.effect` on the `Surface` (303-311) has no padding. This needs a capture.
- **H2.** The unit's long body wraps to about four to six lines at 323 px and 12 px, so the 96 px popup viewport clips its end. Font metrics are unmeasured.
- **H3.** The unread dot is not in the card's accessible name (113-115), and its child name (400) may not reach the tree. a11y-audit reads the tree.
- **H4.** `Behavior on x` (637-639) also animates the live drag translation, so a swipe may trail the pointer by up to 180 ms. Handed to review-animations.
- **H5.** The entrance scale runs under reduced motion (271-273, 60 ms). `AGENTS.md` removes one-shot position motion under reduced motion; a scale is not a position. Handed to review-animations.

Not examined: live geometry, captures and owner review (no session under this audit). Center mode with `showActions` true, swatch, selected, unread and archived states in a live window. Real pointer swipe and drag. Keyboard in the center (`actionFocusIndex`). Reduced effects (the shadow is off). Text scaling and locale. Light or high-contrast themes (none read). Tokens other than deep-night.

Evidence for this section: source-reviewed. Runtime-exercised: none. Owner-accepted: none.
