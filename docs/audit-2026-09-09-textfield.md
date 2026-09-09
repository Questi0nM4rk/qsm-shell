# TextField audit 2026-09-09 (ui-audit + ux-audit)

Captures and tree dumps referenced below lived in the session scratchpad and were not kept; the tables carry the measured values.

Target: the live `text-input` scenario (`previews/units/TextField.qml` hosting
`qml/QsmShell/Components/TextField.qml`), theme `deep-night`.

Design sources used as "expected": `docs/components/TextField.md`,
`tokens/deep-night.json`, the **Component laws** section of `AGENTS.md`,
`qml/QsmShell/Style/Motion.qml`, and the two audit rubrics
(`ui-audit/references/rubric.md`, `ux-audit/references/heuristics.md`).

Standing owner ruling, **not** a finding: the focus edge has one owner,
`StateLayer` (keyboard ring); the background border means only `failed`;
pointer focus shows as a surface lift plus the caret. Verified in
`tree-04-focus-tab.json` (ring present) vs `tree-05-focus-click.json` (ring
absent, caret present) and in `tree-30-failed-tabfocus.json` (ring paints
danger over the danger border, error stays error while focused).

## Measurement environment

- Output `eDP-1`, 1920x1080 physical, Hyprland logical scale **1.2**; second
  output `HDMI-A-1` present.
- Preview window tiled at logical `(70,26)` size `746x848`. `qml`'s QQuickView
  resizes the root object to the view, so the scene is 746x848, not the
  declared 800x500, the load-time dump (`tree-01-rest-textfilled-lg.json`)
  reports 800x500 and is superseded by `tree-02-rest.json` onward.
- Screen mapping used for every pixel probe:
  `physical = (window_x + scene_x) * 1.2`, `(window_y + scene_y) * 1.2`.
  Verified by sampling the field surface (`#21142B`, exact token) at physical
  `304,672`. `window_x` was `70` for the whole trace except the last relaunch,
  which the tiler placed at `828` (`shot-37`, `shot-38`, probes at `1213+`);
  the coordinates in each finding row match the window that shot was taken in.
- `grim` on this compositor **includes the pointer**, so cursor shape is
  readable from captures; every geometry crop was taken with the pointer
  parked outside the crop.
- `decoration:active_opacity` is `0.98`. Token colours still sample exact or
  within 1/255 (`#382A48` hover read exactly; `#1c0e27` read as `#1D0F28`), so
  contrast numbers carry a ±1/255 sampling caveat. Pure token-pair ratios were
  additionally computed on a synthetic swatch (`swatch-tokens.png`).
- Locale `en_US.UTF-8`, so `DoubleValidator` takes `.` as the decimal point and
  `,` as a group separator. Platform `cursor-blink-time` 1200ms →
  `caret.halfPeriod` 600ms.

## State-space map (ux deliverable #1)

Every row below was visited; the artefact column names the evidence.

| state | how reached | tree | capture |
| --- | --- | --- | --- |
| rest, lg, filled | load | `tree-02-rest.json`, `tree-35-fresh-rest.json` | `shot-02-rest.png`, `crop-02-rest-field.png` |
| hover (body) | pointer scene (350,534) | `tree-03-hover.json` | `shot-03-hover.png` |
| focus by Tab (ring) | Tab from unfocused | `tree-04-focus-tab.json`, `tree-tab1..6.json` | `shot-04-focus-tab.png`, `crop-04-focus-tab.png`, `crop-04-ring-leftedge-z8.png` |
| focus by click (lift + caret, no ring) | click on the text | `tree-05-focus-click.json` | `shot-05-focus-click.png`, `crop-05-focus-click.png`, `crop-05-caret-z8.png` |
| Tab after a click | Tab while pointer-focused | `tree-08-tab-after-click.json` | n/a |
| select all | Ctrl+A | `tree-06-selectall.json` | `shot-06-selectall.png`, `crop-06-selection-z4.png` |
| long value (79 chars typed) | `ydotool type` | `tree-07-longvalue.json` | `shot-07-longvalue.png`, `shot-07b-longvalue-caret.png`, `crop-07b-caret-trailing-z8.png` |
| empty / placeholder | Ctrl+A, Delete | `tree-09-empty-placeholder.json` | `shot-09-empty.png`, `shot-09b-empty-caret.png`, `crop-09b-caret-placeholder-z8.png` |
| password (masked) | strip purpose→password | `tree-10-password.json`, `tree-10b-password-settled.json` | `shot-10-password.png`, `crop-10-password.png` |
| trailing action hovered | pointer scene (538,534) | `tree-11-trailing-hover.json` | `shot-11-trailing-hover.png`, `crop-11-trailing-hover-z6.png` |
| trailing action pressed (held) | `ydotool click 0x40` | `tree-13-trailing-pressed.json` | n/a |
| password revealed | click the eye | `tree-15-password-revealed.json` | `shot-15-password-revealed.png`, `crop-15-password-revealed.png` |
| number | strip purpose→number | `tree-16-number.json` | `shot-16-number.png`, `crop-16-number.png` |
| number, letters rejected | type `abc` over a selection | `tree-17-number-invalid-letters.json` | n/a |
| number, intermediate `42,42.` | type `42,` then `42.` | `tree-18/19-*.json` | `shot-19-number-intermediate.png` |
| Return on an unacceptable value | Return | `tree-20-after-return-invalid.json` | `shot-19b-before-return.png` vs `shot-20-after-return-invalid.png` |
| search purpose (leading action) | strip purpose→search | `tree-21-search.json` | `shot-21-search.png`, `crop-21-search.png` |
| leading action hovered | pointer scene (205,534) | `tree-22-leading-hover.json` | `crop-22-leading-hover-z6.png` |
| failed | strip failed→on | `tree-23-failed.json` | `shot-23-failed.png`, `crop-23-failed.png` |
| failed + keyboard focus | disable/enable, then Tab | `tree-30-failed-tabfocus.json` | `shot-30-failed-tabfocus.png`, `crop-30-failed-tabfocus.png` |
| failed at rest, never focused | fresh window, strip only, pointer off the field | `tree-38-failed-rest-clean.json` | `shot-38-failed-rest-clean.png`, `crop-38-failed-rest-clean.png` |
| readOnly (focused) | strip readOnly→on | `tree-24-readonly.json` | `shot-24-readonly.png` |
| readOnly, clicked | click the body | `tree-25-readonly-clicked.json` | `shot-25-readonly-clicked.png` |
| readOnly, hovered, unfocused | disable/enable, hover | `tree-29-readonly-hover-unfocused.json` | `shot-29-readonly-hover.png` |
| readOnly at rest, never focused | fresh window, strip only | `tree-36-readonly-rest-clean.json` | `shot-36-readonly-rest-clean.png`, `crop-36-readonly-rest-clean.png` |
| disabled | strip state→disabled | `tree-26-disabled.json` | `shot-26-disabled.png`, `crop-26-disabled-trailing-z8.png` |
| disabled + Tab (must skip) | Tab | `tree-27-disabled-tab.json` | n/a |
| after clear() via trailing action | click the × | `tree-31-after-clear.json` | n/a |
| size sm / md / lg | strip size | `tree-28-size-sm/md/lg.json` | `shot-28-size-*.png`, `crop-28-size-sm.png`, `crop-28-size-md.png` |
| control: a strip Capsule hovered | pointer over `search` capsule | `tree-12-capsule-hover-control.json` | n/a |
| second output | `grim -o HDMI-A-1` | n/a | `shot-32-hdmi.png` |

### Geometry that conforms (recorded, no finding)

From `tree-02-rest.json` (lg, filled):

- background `#21142b` (`surface`), `radius 12` (`radiusMd`).
- `leftPadding` 40 = `space3` 12 + leading 20 + `space2` 8; `rightPadding`
  44 = 12 + trailing 24 + 8. Left inset 12 == right inset 12; both slot gaps
  8. Every horizontal gap is 12 / 8 / 2, three clusters, all tokens.
- Vertical centring: leading slot margins 16/16; trailing 14/14; caret
  15.5/15.5.
- Heights `sm 32` / `md 40` / `lg 52` = `controlHeightSm|controlHeight|
  controlHeightLg`; text `12 / 14 / 18` = `textSm|textMd|textLg` (steps 1.167x
  and 1.286x, both ≥1.125x).
- Long value: field width stays 380; caret right edge lands exactly on the
  content clip edge (517+2 = 519) and `527 − 519 = 8` = `space2` to the
  trailing slot, the documented `spaceTight` scroll-end inset works.
- Placeholder and value share x (223), size (18) and baseline: ink-row profile
  bottom row identical (row 31 in both `shot-02-rest.png` and
  `shot-09b-empty-caret.png`, band `68x52+352+648`); tops differ by 1 row,
  explained by the glyph sets (`Pl` vs `En`).
- Radii inventory: 12 (background), 12 (focus ring), 12 (`IconButton`
  focusRadius = h/2), 4 (caret, `radiusXs`). All tokens.
- Contrast that passes (synthetic token swatch): value text on surface 15.73,
  on surfaceHover 11.85; placeholder 7.81 / 5.88; caret and ring accent
  8.28 / 6.24; danger 7.81 / 5.88; hover state ratio surface→surfaceHover
  **1.33** (≥1.20 required). Selection measured live: band `#C2A3E6` with
  selected glyph `#1C0F27` → **8.44:1**.
- Enabled slot glyphs are matched: leading 7.61:1, trailing 7.59:1.
- Disabled: root `opacity 0.35` (`opacityDisabled`), background reverts to
  `surface`, caret gone, and Tab does not focus it (`tree-27-disabled-tab.json`).
- Cursor shapes read off captures: I-beam over the editable body
  (`crop-07-longvalue.png`), pointing hand over the trailing action
  (`crop-11-trailing-hover-z6.png`), pointing hand over the search leading
  action (`crop-22-leading-hover-z6.png`).
- Reveal keeps the input a password: `inputType` unchanged, key glyph still in
  the leading slot, only the mask and the eye/eye-off glyph change
  (`crop-10-password.png` → `crop-15-password-revealed.png`).
- Number validator rejects letters outright: `abc` typed over a selected
  `42.5` left the text at `42.5` (`tree-17-number-invalid-letters.json`).

## ui-audit findings

| id | pass | element | evidence (measured) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| UI-1 | 4 Color `source-conflict` | resting field boundary | `shot-02-rest.png` @700,672 = `#23162D` vs @790,672 = `#1F112A` → **1.04:1**; left-edge probe walks `#1C0E27 → #1E1129 → #21142B` with no stroke between; token pair `surface`/`background` on `swatch-tokens.png` = **1.05:1** | (a) ≥3:1 for the visual boundary of a UI component (rubric Pass 4 / WCAG 2.1 SC 1.4.11). (b) `docs/components/TextField.md` `not designed: ... filled/outlined variants`; `StateLayer.qml:11`, which says a thing at rest gets nothing and the shell paints no box around it; the standing ruling that the background border means only `failed` (`TextField.qml:164,172`) | the field's resting edge is invisible against the shell background; only the 12px corner curve hints that a box is there. The rubric wants a 3:1 boundary, the component laws forbid a resting box, so the owner rules rather than the audit picking. Human trial #3 is the tiebreaker | major |
| UI-2 | 3 Geometry | `failed` border, 1px at dpr 1.2, hovered/pointer-focused substate | the 1px stroke covers 100% of a device row on the top edge and ~80% of a device column on the sides, so the sides render weaker. Against `surfaceHover`: top `#DE7B87` → **4.58:1**, left `#A45F71` → **2.76:1** (`shot-23-failed.png` @530,641 and @304,672 vs @700,672). Measured for contrast: at rest the same edges give **5.85:1** and **3.25:1** (`shot-38-failed-rest-clean.png` @1414,641 and @1214,672), and with the keyboard ring stacked on the border **4.18:1** on the left (`shot-30-failed-tabfocus.png` @304,672). Token `danger` `#ff8b94` renders at 87% (top) and 64% (side) | ≥3:1 for an essential state indicator (rubric Pass 4); rubric Pass 3 flags strokes that render inconsistently across scales; `border.width: root.failed ? 1 : 0` (`TextField.qml:172`) | the failure signal renders at two strengths on one rectangle. It passes 3:1 at rest and passes again once the keyboard ring stacks on it; it dips to 2.76:1 in exactly one substate, failed plus hover or pointer focus without the ring, which is the moment a person reaches for the field to repair it | minor |
| UI-3 | 3 Geometry | keyboard focus ring, same 1px stroke | `shot-04-focus-tab.png`: top edge `#C2A3E6` → **6.07:1**, left edge `#9F84BE` → **4.03:1** (accent `#c5a5e9` rendered at 98% vs 78%) | one uniform ring for every control (`StateLayer.qml:92-104`) | the ring's perimeter weight varies 1.5x; still ≥3:1 everywhere, so it reads, same root cause as UI-2 | polish |
| UI-4 | 5 Typography/icons | slot glyph sizes in one row | `tree-02-rest.json`: leading `SvgIcon` 20x20, trailing `SvgIcon` 16x16, same row, same colour | icons in one cluster share a bounding size within 1px (rubric Pass 5) | two icon sizes inside one control; `previews/units/TextField.qml:66` uses `Style.iconMd`, `:85` uses `Style.iconSm`, a unit choice, not the component's | minor |
| UI-5 | 5 Typography/icons | leading glyph ignores `size` | `tree-28-size-sm/md/lg.json`: glyph 20x20 at every size while text is 12 / 14 / 18 → icon:text 1.67x at `sm`, 1.43x at `md`, 1.11x at `lg`. Visible in `crop-28-size-sm.png` | sizes must form one scale (rubric Pass 5); the component keeps one default and lets the call site pass a value (AGENTS "No numbers in a component") | at `sm` the purpose glyph is two-thirds taller than the value's cap height and dominates the row; the unit hardcodes `Style.iconMd` | minor |
| UI-6 | 2 Spacing | trailing padding survives an emptied slot | `tree-31-after-clear.json` and `tree-09-empty-placeholder.json`: trailing slot `Item` still `24x24 @(527,522)` holding an `active: false` `Loader` with no item; `rightPadding` stays 44 (`563 − 519`) with nothing painted | "An empty slot takes no space" (AGENTS Component laws); `rightPadding` arithmetic `TextField.qml:149` | an empty field reserves 24px plus an 8px gap for an action that is not rendered; `hasContent: children.length > 0` (`TextField.qml:198`) counts the Loader, not its item, so the natural conditional-action composition defeats it | minor |
| UI-7 | 3 Geometry | caret lands on fractional x | caret x = `307.5` (`tree-04`), `300.4` (`tree-05`), `295.3` (`tree-21`), `427.1` (`tree-10b`); y is `523.5` in every state. At 307.5 the 2px bar smears over three device columns: `shot-09b-empty-caret.png` @352-356 = `#C2A3E6`, `#BA9EE1`, `#A8A6BF` | rubric Pass 3: fractional positions on static elements are a pixel-snapping finding | the insertion mark's crispness depends on where in the string it sits; at 517 (`tree-07`) it renders two solid columns, at 307.5 it does not | polish |
| UI-8 | 4 Color | subpixel RGB fringing on glyph edges | `shot-02-rest.png` @388,672 = `#3A162C` (red-shifted) and @392,672 = `#D9ECF6` (cyan-shifted) against text `#f6f1f9` on `#21142b`; visible at 8x in `crop-09b-caret-placeholder-z8.png` and `crop-22-leading-hover-z6.png` | rubric Pass 4: a hue belonging to neither fg nor bg is a real fringe | the platform renders text with RGB subpixel AA; this is scene-wide (the strip `Prose` fringes identically), not a TextField defect, filed so it is not re-discovered | polish |
| UI-9 | 4 Color | disabled field dims in three steps | `shot-26-disabled.png`: value text **2.88:1**, leading glyph **2.03:1**, trailing action glyph **1.23:1** (brightest pixels `#625E70`, `#52455E`, `#32243C`). Enabled equivalents 7.61 and 7.59 | `StateLayer.qml:22`, where disabled means the host dims itself and the layer simply stops answering (AGENTS Component laws): one dim, one place. `TextField.qml:156` `opacity 0.35` × `IconButton.qml:19` `opacity 0.35` = 0.1225 effective | inside one disabled field the action all but disappears while the label is merely dim; the cascade dims the `IconButton` a second time | minor |

**Where each fix lands.** UI-4 and UI-5 are the unit's composition
(`previews/units/TextField.qml:54,66,85`), not the component. UI-9 spans
`TextField.qml:156` and `IconButton.qml:19` together. UI-1, UI-2, UI-3, UI-6
and UI-7 land on `TextField.qml` (UI-6 on `hasContent`/padding at `:148-149,198`).

## ux-audit findings

| id | check | interaction | evidence (measured/traced) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| UX-1 | 2 Affordance & feedback | hover a slot action | pointer at scene `(538,534)`, inside the trailing `IconButton` rect `(527,522 24x24)`: glyph `scale` stays 1 (`tree-11-trailing-hover.json`). Same for the search leading action at `(205,534)`: `scale` 1 (`tree-22-leading-hover.json`). Control: a strip `Capsule` under the pointer reports `scale 1.04` (`tree-12-capsule-hover-control.json`), so growth works in this host. Press still works: glyph `scale 0.86` while held (`tree-13-trailing-pressed.json`) | hover acknowledgment ≤100ms for every input (heuristics Check 2); `hoverScale: 1.15` (`IconButton.qml:39`) via `StateLayer` growth (`StateLayer.qml:72-87`); AGENTS law "a hover reader belongs on the ANCESTOR of the surfaces, never stacked with them" | slot actions never acknowledge hover. `cursorArea` (`MouseArea`, `hoverEnabled: true`, `anchors.fill`, declared last so topmost, `TextField.qml:425-435`) consumes hover from the slots' `HoverHandler`s; it rejects the press (`mouse.accepted = false`), which is why the click and the press growth survive and only hover dies | major |
| UX-2 | 2 Affordance & feedback | hover a `readOnly` field | readOnly, never focused, pointer over the body: background `#382a48` (`shot-29-readonly-hover.png` @700,672; `tree-29-readonly-hover-unfocused.json`), byte-identical to an editable field's hover (`tree-03-hover.json`). A subsequent click yields no caret (`tree-25-readonly-clicked.json`) | "Unavailable and not-a-target are different states" (AGENTS); resting/hover affordance gradient must sort every element correctly (heuristics Check 2). `StateLayer.interactive: root.enabled && !input.readOnly` already excludes readOnly (`TextField.qml:384`) | the field's own two state owners disagree: the layer stops answering, the background answers anyway. A person gets the editable-field lift, clicks, gets no caret, types, and the keystrokes vanish with no answer | major |
| UX-3 | 2 Affordance & feedback | Return on an unacceptable value | field holding `42,42.` (Intermediate for `DoubleValidator` in en_US, `tree-19-number-intermediate.json`); Return pressed → `ui-capture diff shot-19b-before-return.png shot-20-after-return-invalid.png` distortion **0.000152** (caret blink phase only), text unchanged, no border, no colour change | "every input event gets a visible answer" (heuristics Check 2); `accept()` returns false and emits nothing when `!acceptableInput` (`TextField.qml:105-110`) | Return is a silent no-op and the frame is identical to a valid field's. The component correctly exposes `acceptableInput` and leaves the copy to the host, but the unit renders neither, so the proof harness does not play the host for this fact, the state cannot be judged in the window | major |
| UX-4 | 3 Target ergonomics | the search leading action | `textFieldSearchAction` hit rect **20x20** (`tree-21-search.json`), a real target (`onClicked: root.accept()`, `previews/units/TextField.qml:56`) | 24x24 hard floor (WCAG 2.5.8 AA), 32x32 comfortable for frequent use (heuristics Check 3) | search submit is 400px² against a 576px² floor; `padding: 0` (`previews/units/TextField.qml:54`) was chosen to keep the text column aligned with the plain-glyph variants, and it costs the target | minor |
| UX-5 | 3 Target ergonomics | the trailing clear/reveal action | hit rect **24x24**, glyph 16x16 plus `padding: Style.space1` (`tree-02-rest.json`); edge-to-edge gap to the editable body 8px, to the field edge 12px | 24x24 floor met; 32x32 comfortable for frequent use (heuristics Check 3) | clear and reveal sit exactly on the floor. Acceptable, recorded because the field is a frequent-use surface | polish |
| UX-6 | 4 Mode & state visibility `source-conflict` | `readOnly` at rest | fresh window, readOnly set from the strip, field never focused, pointer parked: surface `#21142b`, radius 12, no caret, the only difference from the editable rest frame is the consumer's trailing glyph at `opacity 0.35`; full-frame diff `shot-35-fresh-rest.png` vs `shot-36-readonly-rest-clean.png` distortion **0.000315** | (a) heuristics Check 4 single-frame test: a mode with no distinguishing pixel is a finding. (b) AGENTS law: "A row that only REPORTS is showing the truth at full strength and simply is not clickable. Dimming it to say 'you cannot click this' also says 'this reading is stale'", which forbids the usual fix | a readOnly field composed without a trailing action has no resting mark at all; the two sources point opposite ways, so the owner rules which wins rather than the audit picking | minor |
| UX-7 | 4 Mode & state visibility | keyboard ring after a pointer click | after a click into the body, Tab leaves focus in the field and the ring stays absent (`tree-08-tab-after-click.json`, caret still at 517, no ring rect) versus the ring present on the first Tab from unfocused (`tree-04-focus-tab.json`). `_focusOffTheKeyChain` clears only on focus LOSS (`TextField.qml:272`) | the ring is the keyboard "you are here" mark (owner ruling; `StateLayer.qml:17-21`) | on a surface whose only tab stop is the field, a launcher search box, one click removes the ring for the rest of the focus session, because Tab wraps to the same item and focus never leaves to reset the flag | minor |
| UX-8 | 4 Mode & state visibility | disable then re-enable | strip `state` → disabled → enabled, pointer parked, no key pressed: caret present AND the ring rect present (`tree-34-editable-rest-probe.json`), i.e. the field took keyboard focus by itself and painted the keyboard mark | the ring means focus arrived by the key chain (`TextField.qml:390-403`) | a host that disables a field temporarily (while saving, while a request is in flight) gets keyboard focus and the keyboard ring back unasked, and the ring claims a Tab arrival that never happened | minor |

**Where each fix lands.** UX-3 and UX-4 are the unit's, not the component's:
UX-3's component contract is correct (`acceptableInput` is exposed and `failed`
stays a host verdict per the AGENTS law), and the missing piece is that
`previews/units/TextField.qml` never renders it, so no `TextField.qml` edit
should be made for UX-3. UX-4 is `padding: 0` at
`previews/units/TextField.qml:54`. UX-5 is a recorded fact, not a fix. UX-1,
UX-2, UX-6, UX-7 and UX-8 land on `TextField.qml` (`:425-435`, `:164`, `:164`,
`:272`, `:390-403`).

## Hypotheses (not measurable with the channels available)

- **Hover and press transition durations.** `Motion.micro` 130ms and
  `Motion.press` 80ms (`Motion.qml:24,26`; `TextField.qml:176,179,371`), with
  `Style.reducedMotion` false in the preview backend
  (`previews/StyleBackend.qml:6`). Settling is confirmed, every hover capture
  reads exactly `#382a48`, but `grim` costs ~450ms per frame, so a 130ms curve
  cannot be resolved. No duration claim is made.
- **Caret blink period.** Platform `cursor-blink-time` reads 1200ms, so
  `caret.halfPeriod` is 600ms. `opacity: 0` was observed in `tree-tab6`,
  `tree-10b`, `tree-16`, `tree-19`, `tree-31`, blinking works; the period was
  not timed.
- **Caret travel.** `Behavior on x` uses `Motion.press`; the tree dump is
  F12-driven, so no mid-flight sample exists. A `Qt.callLater` dump right after
  a strip click caught the caret at 223 while the cursor delegate was already
  at 427.1 (`tree-10-password.json`) and the settled dump agreed at 427.1
  (`tree-10b`), a dump-timing artefact, not a binding fault.
- **Caret colour in a failed field.** The caret stays `accent` `#c5a5e9` while
  the border and the ring are `danger` (`tree-30-failed-tabfocus.json`). No
  design source states which colour the insertion point should follow, so this
  is not filed as a finding.
- **Caret adjacency to the first glyph.** At cursor position 0 the 2px caret
  and the placeholder's `E` stem touch with no gap between them
  (`shot-09b-empty-caret.png` @352-356: caret, caret, glyph blend, glyph
  blend) and read as one mark at 8x (`crop-09b-caret-placeholder-z8.png`).
  Whether that is worse than a stock 1px caret is a taste call for the owner,
  not a measurement.

## Needs human trial

Each script assumes `cd $HOME/Projects/qsm-shell`.

1. **Reduced motion.** No control exposes it and the fixture pins it false.
   Temporarily set `reducedMotion: true` in `previews/StyleBackend.qml`, run
   `npm run preview -- text-input`, click into the body, hold an arrow key, and
   confirm the caret stops blinking (`TextField.qml:364` guard) while the hover
   colour still settles. Revert the fixture afterwards.
2. **Typing feel at speed.** `npm run preview -- text-input`, click into the
   body, type a 60-character sentence at full speed, and watch whether the
   caret ever blinks out mid-burst or trails the last glyph. This is the exact
   failure the custom caret exists to fix (`TextField.qml:321-331`) and no
   capture can judge it.
3. **UI-1 outside the preview backdrop.** The 1.04:1 boundary was measured
   against the preview host's `#1c0e27`. Put the same field on
   `surfaceRaised` (`#2d1f3a`) and on `bandFill` (`#15081e`) in a scratch
   preview and judge whether the finding survives the surfaces the consumer
   actually uses. That decides whether UI-1 is a token-pair problem or a
   resting-border problem.
4. **Password reveal with a real paste.** Purpose → password, click the body,
   `Ctrl+V` a long secret from the password manager, click the eye twice, and
   confirm the dots and the plain text land on the same glyph positions and the
   scroll offset does not jump.
5. **Escape and accept in a real surface.** `escaped` and `accepted` have no
   visible consumer in the unit, so their silence here proves nothing. Drive
   Escape and Return in the launcher and judge whether the field's behaviour is
   right where a host is listening.

## Not examined

- **Pass 6 Motion**, durations were source-verified and settling confirmed,
  but no timeline was sampled; see Hypotheses. The F12-driven dump cannot be
  polled in a tight loop, which is the rubric's primary motion technique.
- **Pass 7 Multi-monitor**, not applicable by construction rather than
  skipped. The preview is a single tiled window on `eDP-1`
  (`hyprctl clients`: `monitor: 0`); `HDMI-A-1` was captured
  (`shot-32-hdmi.png`) and holds no instance of the surface, so there is
  nothing to compare per screen.
- **Scale factors other than 1.2.** UI-2, UI-3 and UI-7 are
  device-pixel-ratio dependent; a 1.0 or 2.0 output would render the 1px
  strokes differently. Only 1.2 was measured.
- **`sm` and `md` in the non-resting states.** Only `lg` was driven through the
  full state set; `sm` and `md` were measured for geometry and type only
  (`tree-28-size-sm/md.json`).
- **Wheel over the field.** `AGENTS.md` records that synthetic `mouseWheel`
  never reaches a `WheelHandler` under this Qt6 Wayland QPA, and `TextField`
  declares none, so there was nothing to exercise.
- **`keyPressed` interception, `moveUp`/`moveDown`, `edited`,
  `selectionClaimed`**, behaviour signals with no rendering. They belong to
  `tests/units/tst_TextField.qml`, not to a visual or interaction audit of the
  frame.
- **Host-supplied validators.** Only the built-in `DoubleValidator` was
  exercised; a range or integer validator, and `acceptableInput` under one,
  were not.
- **Themes other than `deep-night`.**
- **`leadingCursorShape` default (`Qt.IBeamCursor`).** Only the `search`
  purpose's overridden pointing hand was captured; the plain-glyph purposes'
  leading cursor was not sampled.
- **Interruption cost (heuristics Check 5).** A text field shows nothing
  unbidden, no notification, OSD or popup originates here, so the check has
  no subject. Recorded rather than scored.

## Artefacts

All under
`/tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/audit/`.

Trees: `tree-01-rest-textfilled-lg.json`, `tree-02-rest.json`,
`tree-03-hover.json`, `tree-04-focus-tab.json`, `tree-05-focus-click.json`,
`tree-06-selectall.json`, `tree-07-longvalue.json`,
`tree-08-tab-after-click.json`, `tree-09-empty-placeholder.json`,
`tree-10-password.json`, `tree-10b-password-settled.json`,
`tree-11-trailing-hover.json`, `tree-12-capsule-hover-control.json`,
`tree-13-trailing-pressed.json`, `tree-14-password-revealed.json`,
`tree-15-password-revealed.json`, `tree-16-number.json`,
`tree-17-number-invalid-letters.json`, `tree-18-number-comma.json`,
`tree-19-number-intermediate.json`, `tree-20-after-return-invalid.json`,
`tree-21-search.json`, `tree-22-leading-hover.json`, `tree-23-failed.json`,
`tree-24-readonly.json`, `tree-25-readonly-clicked.json`,
`tree-26-disabled.json`, `tree-27-disabled-tab.json`,
`tree-28-size-sm.json`, `tree-28-size-md.json`, `tree-28-size-lg.json`,
`tree-29-readonly-hover-unfocused.json`, `tree-30-failed-tabfocus.json`,
`tree-31-after-clear.json`, `tree-33-readonly-rest.json`,
`tree-34-editable-rest-probe.json`, `tree-35-fresh-rest.json`,
`tree-36-readonly-rest-clean.json`, `tree-37-failed-rest-clean.json`,
`tree-38-failed-rest-clean.json`, `tree-tab1.json` … `tree-tab6.json`.

Captures: `shot-01-rest.png`, `shot-02-rest.png`, `shot-03-hover.png`,
`shot-04-focus-tab.png`, `shot-05-focus-click.png`, `shot-06-selectall.png`,
`shot-07-longvalue.png`, `shot-07b-longvalue-caret.png`, `shot-09-empty.png`,
`shot-09b-empty-caret.png`, `shot-10-password.png`,
`shot-11-trailing-hover.png`, `shot-14-password-revealed.png`,
`shot-15-password-revealed.png`, `shot-16-number.png`,
`shot-19-number-intermediate.png`, `shot-19b-before-return.png`,
`shot-20-after-return-invalid.png`, `shot-21-search.png`,
`shot-22-leading-hover.png`, `shot-23-failed.png`, `shot-24-readonly.png`,
`shot-25-readonly-clicked.png`, `shot-26-disabled.png`,
`shot-28-size-sm.png`, `shot-28-size-md.png`, `shot-28-size-lg.png`,
`shot-29-readonly-hover.png`, `shot-30-failed-tabfocus.png`,
`shot-32-hdmi.png`, `shot-33-readonly-rest.png`, `shot-35-fresh-rest.png`,
`shot-36-readonly-rest-clean.png`, `shot-37-failed-rest-clean.png`,
`shot-38-failed-rest-clean.png`.

Crops (judged at zoom 2–8): `crop-01-window.png`, `crop-02-rest-field.png`,
`crop-04-focus-tab.png`, `crop-04-ring-leftedge-z8.png`,
`crop-04-caret-z8.png`, `crop-05-focus-click.png`, `crop-05-caret-z8.png`,
`crop-06-selectall.png`, `crop-06-selection-z4.png`, `crop-07-longvalue.png`,
`crop-07-caret-trailing-z8.png`, `crop-07b-caret-trailing-z8.png`,
`crop-09-empty.png`, `crop-09b-caret-placeholder-z8.png`,
`crop-10-password.png`, `crop-11-trailing-hover-z6.png`,
`crop-14-password-revealed.png`, `crop-15-password-revealed.png`,
`crop-16-number.png`, `crop-19-number-intermediate.png`,
`crop-21-search.png`, `crop-22-leading-hover-z6.png`, `crop-23-failed.png`,
`crop-24-readonly.png`, `crop-25-readonly-clicked.png`,
`crop-26-disabled.png`, `crop-26-disabled-trailing-z8.png`,
`crop-28-size-sm.png`, `crop-28-size-md.png`, `crop-29-readonly-hover.png`,
`crop-30-failed-tabfocus.png`, `crop-33-readonly-rest.png`,
`crop-36-readonly-rest-clean.png`, `crop-37-failed-rest-clean.png`,
`crop-38-failed-rest-clean.png`.

Helpers: `swatch-tokens.png` (token-pair contrast reference),
`field.jq` (flattens the `TextField` subtree), `moveto.sh` (damped relative
pointer move, `ydotool --absolute` silently does nothing on this machine),
`btn.sh` (strip capsule → screen coordinates).
