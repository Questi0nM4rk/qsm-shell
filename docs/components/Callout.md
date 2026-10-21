# Callout

A persistent inline message with a recovery action; the host owns the condition, the copy and what the action does.
states: info, success, warning and danger; tone sets the rule, the glyph and the surface tint together, never colour alone; title, body and action sections collapse when empty (an empty action host adds no gap); an unknown tone or a missing icon file reports on the error stream.
actions: none of its own; the consumer's recovery controls ride the default `actions` slot.
pointer: none on the message itself; slotted controls keep their own targets and wheel passes through.
keyboard: none on the message itself; slotted controls keep their own tab stops and keys.
screen reader: icon, hue and rule carry the tone as three channels; title and body are plain text roles.
size: natural width is the constant `controlWidth` and a host sets `width`; height is content plus double box inset; the rule is one mark width and starts where the corner arc meets the edge; radius is `radiusMd`; long copy wraps or elides, never grows the control.
tokens: space3, space1, space2, iconMd, radiusMd, markThickness, the semantic tone set and Prose; no local colours or measurements.
motion: none; a persistent message never implies interactivity through motion.
not designed: dismissal, transient toast behaviour, progress or form input; use NotificationCard, EmptyState or Field for those.

## UIX audit

Fix status: C-01, C-02, C-03 and C-05 are fixed (source-reviewed, qmllint-checked; no capture or window run, so not load-checked or runtime-exercised). C-04 is open. Owner-accepted: none.

Evidence: source-reviewed only. No Workbench session, capture, item-tree dump or accessibility tree was taken, so every geometry value below is derived from the source and `tokens/deep-night.json` and marked *derived*. Runtime-exercised: none. Owner-accepted: none.

Read: `Callout.qml`, `Card.qml`, `Prose.qml`, `SvgIcon.qml`, `Capsule.qml` (lines 25-85 and 160-185), `workbench/units/Callout.qml`, the `callout` story in `workbench/stories.json`, `tokens/deep-night.json`. Consumers: none; a search of the qsm-desktop checkout finds no `Callout` reference.

### Purpose and consequence

A persistent inline message for a condition of the surface it sits in that is still true (`Callout.qml:6-22`). The person learns what failed, where, and what to do, and the message stays until the condition clears.

### Controls, states, routes

- Tones `info`, `success`, `warning`, `danger` are implemented (`Callout.qml:40-57`). Any other string falls to `info` (finding C-05).
- `title`, `body`, `icon` override are implemented. Title and body collapse when empty (`Callout.qml:103`, `:109`).
- `actions` is the default slot, a `RowLayout` (`Callout.qml:38`, `:114-119`).
- Not designed: dismissal, progress, form input (line 12 above).
- Unit controls: tone (4), copy (3), mark (2), action (2), `workbench/units/Callout.qml:45-65`. No long-copy option (see Not examined).
- Pointer: the message takes none; no pointer handler in `Callout.qml` or `Card.qml`. The Retry `Capsule` fills its own `StateLayer` (`Capsule.qml:~160-175`), so its input shape is its painted shape.
- Keyboard: the message takes no focus. Retry is `focusPolicy: Qt.StrongFocus` (`Capsule.qml:50`), with Return, Enter and Space calling `activate()` (`Capsule.qml:177-179`, `:78-81`).
- Wheel: none in `Callout.qml` or `Card.qml`. `Capsule.qml` was not checked for a wheel handler.
- Focus ring: Retry's `focused` drives the `StateLayer` ring (`Capsule.qml:46`, `:168-169`). Not driven.
- Accessibility: `Callout`, `Card`, `Prose` and `SvgIcon` set no `Accessible.*` property (grep, 0 matches). Retry sets role `Button` and name `label` (`Capsule.qml:52-53`).

### Sizes, empty, long, failure, cancellation

- Sizes: no size preset. Height is content plus `2 x space3` (`Callout.qml:59`). Width is the consumer's; the unit sets `Style.controlWidth` (380, `workbench/units/Callout.qml:26`). Icon box `iconMd` 20 (`Callout.qml:94`). Rule `markThickness` 3 (`Callout.qml:78`).
- Empty: with title and body empty and the action hidden, the card height is the icon box plus padding, 20 + 24 = 44 px (*derived*).
- Long: the body wraps (`Prose.qml:114`, `WordWrap`). The title elides (`Prose.qml:118`, `ElideRight`). The natural width follows the copy (finding C-01).
- Failure: an unknown tone or an unknown icon name fails silently (C-05).
- Cancellation: none. The message has no action of its own to cancel.

### Visual roles and palette pairs

Computed from token values, not sampled. Body = tone at 0.1 over `surface`, then the card at `surfaceOpacity` 0.9 (`opacity.surface`) over `band`. Backdrop assumed to be `band` (`workbench/units/Callout.qml:21`).

| pair | ratio | expected | 
| --- | --- | --- |
| `text` #f0ecf5 on body | 8.1 | 4.5 (1.4.3) |
| `textMuted` #c5bad1 on body | 5.1 | 4.5 (1.4.3) |
| `info` #89cff1 on body (glyph, rule) | 5.5 | 3 (1.4.11) |
| `success` #a2d3a2 on body | 5.6 | 3 (1.4.11) |
| `warning` #d9c284 on body | 5.4 | 3 (1.4.11) |
| `danger` #f5aeb7 on body | 5.3 | 3 (1.4.11) |

Type roles: title `textMd` 14, bold; body `textSm` 12, regular, muted (`Prose.qml`). Glyph names exist as bundled assets: `circle-check`, `alert-triangle`, `circle-alert`, `info`, `wifi-off` (`qml/QsmShell/assets/icons/`).

### Motion

None. `Callout.qml`, `Card.qml`, `Prose.qml` and `SvgIcon.qml` declare no animation, behaviour or transition. The reduced-motion form does not apply. `review-animations` was not run.

### Pointer geometry (modelled, not measured)

- Input shape: the card has none. Retry's input is its painted capsule, 32 px high (`Capsule.qml:73`, `geometry.controlHeightSm` 32). Width is `contentInset` 12 on each side plus the label. The label width is not measured; 57 px for "Retry" is an assumption, so the capsule is 57 px wide.
- Origin assumption: the pointer rests at the card's centre. The card is 380 x 119 px (*derived*: title 14 + gap 4 + body 37 (two lines at 12 x 1.55, assumed wrap) + gap 4 + action 36 (4 margin + 32) + padding 24 = 119), centred in the unit's 380 x 380 frame, so its centre is (190, 190).
- Target centre: (76, 221.5) in the same frame (*derived*).
- D = 118 px.
- Width model: one-dimensional Fitts with Shannon ID = log2(1 + D/W). Along a downward approach W = 32 (height), ID = 2.23 bits. Along a horizontal approach W = 57 (width), ID = 1.62 bits. Working figure: 2.2 bits.
- Landing tolerance: half-width 16 px along the approach axis. The 24 px floor is cleared by 8 px in height.
- Neighbouring interference: none inside the unit. A consumer's neighbours are not examined.
- Popup corridor and timing: not applicable (not a popup).

### Findings (ui-audit table)

| id | pass | element | evidence (source) | expected | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| C-01 | 3 natural size | root `implicitWidth` | `Callout.qml:60` sums `content.implicitWidth`; the widest child is the body `Prose` (`WordWrap`, no width set, `Prose.qml:114`), whose implicit width is its unwrapped line (*derived* from Qt Text sizing, not run) | AGENTS.md law and DoD 5: natural size constant; long content wraps or elides, never grows the control | Natural width follows the longest body line when the consumer sets no width. The unit hides this by setting `width` (`workbench/units/Callout.qml:26`) | major (fixed, source-reviewed) |
| C-02 | 3 geometry | leading rule at both corners | `Callout.qml:61` radius 12; `:68` `clip: true`; `:73-80` rule is full height, 3 px wide. The 12 px arc meets x = 0 at y = 12 and x = 3 at y ≈ 4 (*derived* from the circle). Item `clip` clips to the item's rectangle, not its radius (Qt Quick documentation). The comment at `:64-67` says clipping fixes this | rule stays inside the rounded silhouette | A 3 px coloured spur at each corner, above y = 12 and below the bottom arc, paints outside the card body | minor (fixed, source-reviewed) |
| C-03 | 2 spacing | body to action gap; empty action slot | `Callout.qml:99` ColumnLayout spacing 4 plus `:117` `Layout.topMargin` 4 gives 8 px between body and action. With `actionable` false the Capsule is still a child (`workbench/units/Callout.qml:34` sets `visible` only), so `:117` keeps the 4 px margin and the zero-height `actionHost` still takes one spacing | `Callout.md` line 4: action section collapses when empty; one 4 px gap (`space1`) | 8 px where 4 is intended, and 8 px of phantom space below the body when no action is shown | minor (fixed, source-reviewed) |
| C-04 | 4 colour, 6 tokens | tint alpha | `Callout.qml:62` `Qt.rgba(..., 0.1)`, a literal | AGENTS.md: no numbers in a component; DoD 6; this record line 10: no local colours or measurements | Literal 0.1; no matching token (opacity set holds `badgeTint` 0.18 and `selected` 0.12) | minor |
| C-05 | failure | tone and icon mapping | `Callout.qml:44-46`, `:54-56` default branches: unknown tone maps to info. `SvgIcon.qml:23-27`: an unknown icon name renders nothing | implementation rule, errors: fail loud, never a silent second path | `tone: "dager"` renders as the calm info message with the info glyph; a mistyped `icon` shows an empty mark | minor (fixed, source-reviewed) |

No defect in: spacing (all gaps from tokens, `Callout.qml:59`, `:85-89`), radius (one `radiusMd`, `:61`; the Capsule's `radiusMd` is not nested near a corner), type roles, shadow and glow (both off, `:27-28`), reserved space (none).

### UX (ux-audit checks)

- Mode visibility: tone is carried by glyph shape (`Callout.qml:48-57`), rule (`:79`) and hue (`:42-47`). No finding.
- Target: Retry is 32 px high by source, above the 24 px floor. Hit area not measured. No finding.
- Vocabulary: Retry's label is the verb only (`workbench/units/Callout.qml:35`); the object lives in the title. Proposal P2.
- Reversibility: no destructive action; the message does not dismiss. No finding.
- Error recovery: the action is optional. A danger message with no action is a dead end (proposal P5).
- Discoverability, interruption, focus movement: not applicable (persistent, not interactive).

### Accessibility (a11y-conformance, criteria from the EN 301 549 mapping)

| criterion | verdict | evidence |
| --- | --- | --- |
| 1.1.1 | not tested | glyph has no `Accessible.*` (`SvgIcon.qml`); decorative by design, title carries the meaning; tree not read |
| 1.3.1 | not tested | title and body are plain `Text` with no role; severity has no structural form (H-01) |
| 1.4.1 | not tested | glyph shape differs per tone (`Callout.qml:48-57`); grayscale capture not taken |
| 1.4.3 | not tested | source-computed 8.1 (text) and 5.1 (muted); not sampled |
| 1.4.4 | not tested | no text-scale check run |
| 1.4.10 | not tested | not examined; body wraps, title elides |
| 1.4.11 | not tested | source-computed 5.3 to 5.6 for glyph and rule; not sampled |
| 1.4.12 | not tested | not examined |
| 1.4.13 | not applicable | no hover or focus content on the message |
| 2.1.1 | not tested | Retry key path is in source (`Capsule.qml:177-179`); not driven |
| 2.1.2 | not tested | not driven |
| 2.4.3 | not tested | one focus stop in the unit; order not recorded |
| 2.4.7 | not tested | Retry focus ring in source (`Capsule.qml:46`, `:168`); not captured |
| 2.4.11 | not tested | no sticky element in source |
| 2.5.1, 2.5.4, 2.5.7 | not applicable | no gesture, motion actuation or drag |
| 2.5.2 | not tested | Retry activation on press (`Capsule.qml:~172`); not driven |
| 2.5.3 | not tested | Retry name equals its label (`Capsule.qml:53`), source only |
| 2.5.8 | not tested | Retry 32 px high (`Capsule.qml:73`), 57 px wide assumed; source meets 24 px |
| 2.2.1, 2.2.2, 2.3.1 | not applicable | no timing, no motion, no flashing |
| 4.1.2 | not tested | Retry role and name in source; the message itself has none (H-01) |
| 4.1.3 | not tested | no alert role or live region (H-02) |

### Source conflicts

- SC-01: natural width (resolved in favour of the constant by C-01). `Callout.md` line 9 says content "never grows beyond its text and slots". AGENTS.md DoD 5 and the law "Natural size is a constant" say the opposite. Owner rules which; C-01 is the consequence of the record's reading.

### Hypotheses (not measured)

- H-01: a screen reader gets no tone. Nothing in `Callout`, `Card`, `Prose` or `SvgIcon` names a severity, so the tone reaches assistive technology only through the words of title and body. Depends on Qt's default accessibility for `Text`. Needs human trial: focus the unit's message in the live window with a screen reader running and read it aloud. Pass: the spoken output names the severity or the title states it.
- H-02: a message that appears because a condition changed is not announced. No alert role or live region exists in the component. Needs human trial: trigger a state change while a screen reader runs. Pass: the message is announced without focus moving.
- H-03: body contrast depends on the backdrop. The card is 0.9 opaque over whatever is behind it (`Card.qml:10`, `:20`). Every ratio above assumes `band` behind it.
- H-04: the corner spur (C-02) is derived from geometry. Confirm with one crop of a corner in the live window.
- H-05: C-01 depends on Qt's implicit width for wrapped text with no width set. Confirm by reading the tree's `implicitWidth` for a long body.

### Proposals (taste and redesign; owner decides)

- P1: expose severity to assistive technology, for example an `Accessible.name` built from tone and title. Shape of the change is for a11y-audit.
- P2: name recovery actions as verb plus object ("Retry connecting the dock"). A bare "Retry" repeats across callouts.
- P3: three channels (glyph, rule, 10 percent hue) say the same thing. Consider dropping one to keep the quiet direction (hierarchy from whitespace and the surface ladder; accent reserved for focus and primary action).
- P4: make the body opaque (`surfaceOpacity` 1) for a message whose legibility matters. Removes H-03.
- P5: a danger message with no action is a dead end. Decide whether the record allows that.
- P6: unit coverage: add a long title, a long body and a narrow width to the copy controls (`workbench/units/Callout.qml:52-56`), per AGENTS.md "long where valid".

### Not examined

- Live window, accessibility tree, captures, item-tree dump: none taken. No Workbench session was started.
- Themes: `deep-night` only. The source has no light or high-contrast token set, so theme parity was not examined.
- Long copy: no unit option; wrap beyond two lines and title elision were not run.
- Retry key path, focus ring, press, hover: inherited from Capsule and not driven here.
- Consumers: no use in qsm-desktop. Real placement, backdrop and width were not examined.
- 200 percent text, narrow reflow: not examined.
- Motion: none exists in the component; `review-animations` not run.
- Passes 4 (sampled colour) and 9 (press state) of ui-audit: not run.
