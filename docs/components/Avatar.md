# Avatar

A masked person picture with a fallback glyph or initials, an optional presence dot and an optional progress ring; it reports identity and never takes input.
states: photo when the image is ready, icon fallback, initials fallback; a status dot shows only when `status` names a tone, a ring only while `progress` is set.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it never claims hover, press, focus or wheel.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: no role of its own; the surrounding row or surface names the person.
size: one `size` box for the picture; the implicit size grows by the ring room (gap plus ring width, whole pixels, even) only while ringed; `radius` defaults to `Style.radiusPill`, a circle; `glyphSize` defaults to two fifths of it and the initials and the glyph snap to the type and icon scales; the presence dot is a fifth of `size` on the 4px rhythm, centred on the rim at 45 degrees.
properties: `source`, `name`, `icon`, `size`, `background`, `status`, `progress`, `progressColor`, `progressTrack`, `ringWidth`, `ringGap`, `glyphSize`, `radius`.
tokens: the Control size table, overlay, text, textMuted, spaceTight, rhythm, textNear, iconNear, Prose, SvgIcon, StatRing and Badge; no local colours; the dot and ring proportions are ratios of `size`.
motion: none of its own; the dot's colour animates in Badge (`Motion.micro`); image and ring settle without animation.
not designed: selection, action, editing, a badge count or a menu; use Badge, IconButton or the host for those.

## UIX audit

Evidence: source-reviewed only. No Workbench session, preview, capture or runtime run was made and no live geometry was read. Contrast ratios and luminance are hand-computed from `tokens/deep-night.json` with the WCAG relative-luminance formula, not sampled from rendered pixels, so they are unverified by a tool.

### Purpose and consequence

Shows which person or thing a picture stands for when no picture is loaded, with an optional presence dot and an optional progress ring. A person scanning a list of people, or a playing track, recognises who or what it is and sees presence or how far through. It finishes no task itself: the row or surface holding it names the person and owns any action.

### Public controls and states

- Properties (`Avatar.qml`): `source`, `name`, `icon`, `size` (real, default `Style.size("Avatar", "md")`, 40), `background` (default `Style.overlay`), `status` (a Badge tone, or empty for no dot), `progress` (-1 for no ring, 0..1 for a ring), `progressColor` (`Style.text`), `progressTrack` (`Style.overlay`), `ringWidth` (`max(2, round(0.06 * size))`), `ringGap` (`Style.spaceTight`), `glyphSize` (`round(0.4 * size)`), `radius` (`Style.radiusPill`, a circle). Not documented above before this section: `icon`, `radius`, `glyphSize`, `ringGap`, `ringWidth`, `progressColor`, `progressTrack`.
- Visible states implemented: photo (image Ready), icon fallback (`icon` set, no image), initials fallback (`name` set, no icon, no image), blank disc (`name` and `icon` both empty, no image; not designed, see P1), presence dot (none or one tone), ring (none, or 0..1).
- Not applicable: rest, hover, press, focus, disabled, selected, loading. Avatar is not interactive.
- Unit coverage (`workbench/units/Avatar.qml:31-51`): identity (initials, one-word, icon), presence (none, online, away), ring (none, half, full), size (md, lg). Not reachable in the unit: the photo path, a failed source, blank identity, radius, the small size.

### Routes

- Pointer: none. `Avatar.qml` has no pointer handler. `Badge.qml`, `StatRing.qml` and `SvgIcon.qml` have none. `Prose.qml` was read to line 80 only and no handler was seen there.
- Wheel: none.
- Keyboard and focus: none. Not a tab stop; no `Accessible.role` on Avatar.
- Screen reader: Avatar sets no role or name. While ringed, `StatRing` exposes an unnamed StaticText (`StatRing.qml:49-52`). Criteria are a11y-audit's; see H3.
- Programmatic: property binding only. No functions and no signals, which matches the `actions: none` line above.

### Sizes, content, failure, cancellation

- Sizes: real and unbounded, no preset. md 40 (default), lg 48 (unit). A consumer states its own size.
- Long content: the name feeds two letters only (`Avatar.qml:74-81`), so a long name cannot widen the disc. See H2 for the code-unit question.
- Empty: `name` and `icon` both empty give a blank overlay disc (`Avatar.qml:98-122`). Undesigned, see P1.
- Failure: a missing or failed image shows the placeholder (`Avatar.qml:108, 116, 151`). No failure is reported to the host, see D6.
- Cancellation: none. A new source restarts the Image; the placeholder shows until it is ready, see H1.

### Visual roles and palette pairs

Token values, hand-computed (no render):

| Pair | Where | Ratio |
| --- | --- | --- |
| textMuted `#c5bad1` on overlay `#4c4357` | initials, default ground | 5.04 |
| text `#f0ecf5` on overlay `#4c4357` | ring fill on track | 8.0 |
| overlay `#4c4357` on band `#271e30` | default ground on the unit band; ring track | 1.7 |
| success `#a2d3a2` on band | presence dot | 9.4 |
| warning `#d9c284` on band | presence dot | 9.1 |
| success on warning | the two presence states | 1.03 |

The record's `accent` token (line 10) is not read by `Avatar.qml`; see D8.

### Motion and reduced motion

Avatar has no animation of its own. `Badge.qml:64-66` animates the dot colour when its tone changes: a ColorAnimation of `Motion.micro` (130 ms in tokens) on `standardEasing`. The photo swaps by hard cut in both directions. The reduced-motion clamp lives in `Motion.qml`, which was not read.

### Pointer geometry

- Input shape: none. No MouseArea, HoverHandler or TapHandler, so D, W and the index ID = log2(1 + D/W) do not apply. No hover zone, hit area, neighbour interference or label origin applies, and no label-weight assumption is needed.
- Painted geometry at md 40 (source arithmetic, no render): disc 40 px, centred. Ringed root 48 px (40 + 2 × (2 + 2)). Ring stroke 2 px, spanning 21.5 to 23.5 px from the centre. Presence dot 8 px (`Badge.qml:53`), box at x 32 to 40 and y 32 to 40 from the disc's top-left. Its centre sits 22.6 px from the disc centre against a disc radius of 20, so the dot bites 1.4 px into the photo rim.
- At lg 48: the dot is still 8 px (17% of the diameter). Its centre sits 28.3 px from the centre against a radius of 24, so it floats 0.3 px clear of the rim. The same corner anchor gives opposite relations at two sizes (D1).

### Findings

Source-backed defects (each cited to file and line; the person-facing effect is in the summary):

- D1, minor: presence dot is a fixed 8 px at every size and anchored to the bounding box corner, not to the rim (`Avatar.qml:157-164`, `Badge.qml:53`). At md it bites into the photo; at lg it floats clear of it, and at lg it is 15% of the diameter against 20% at md. Fix: size the dot from the avatar (`Style.rhythm(size * 0.2)`, 8 at md, 12 at lg) and centre it on the 45-degree rim point, offset `radius * Math.SQRT1_2` from the disc centre.
- D2, minor: initials and glyph are not on the scale (`Avatar.qml:64, 110, 118`). At md the initials are 16 px and the glyph 16 px; the type scale has 14 and 18, so 16 is off-scale. At lg the initials are 21 px (type scale 18 and 22) and the glyph 21 px (icon scale 20 and 24). Fix: `font.pixelSize: Style.textNear(glyphSize)` for the initials and `Style.iconNear(glyphSize)` for the SvgIcon.
- D3, minor: the ring width has a literal floor `Math.max(2, …)` (`Avatar.qml:50`), which breaks "every number comes from Style or Motion". Fix: a stroke token in `tokens/deep-night.json` read through `Style`, not `Style.spaceTight`, which has the same value but is a spacing token.
- D4, minor: the air between picture and ring is 1.5 px at md and 1.25 px at lg, not the 2 px the `ringGap` token says. `StatRing.qml:72` insets the centreline by 0.75 of the stroke, so the inner edge lands at gap minus 0.25 of the ring width (`Avatar.qml:56`). Fix: correct the inset in StatRing or derive `_ringRoom` from the inner edge. StatRing serves every ring consumer, so the owner decides which.
- D5, minor: `size` is a raw real with no preset name; its default reads `Style.size("Avatar", "md")`, the Control family. A consumer that wants a named size adds a `sizes.Avatar` entry and a preset property that calls `Style.size("Avatar", …)`.
- D6, medium: the component does not report its image status, so a host derives it. `Avatar.qml:108, 116, 151` read `portrait.status` privately. A host that wants to avoid a load warning checks the file before passing `source`. AGENTS (component DoD, item 4) requires the component to report facts a host would otherwise derive. Fix: expose the image status (for example `readonly property int imageStatus: portrait.status`).
- D7, minor: the unit never sets `source` (`workbench/units/Avatar.qml:21-29`), so the mask, the photo-to-fallback path and the ring over a photo (the reason the type exists, `Avatar.qml:22-27`) cannot be seen in the preview. There is no blank-identity option, although AGENTS requires empty content where valid. Fix: add a `source` option with a bundled sample image (if none exists, say so) and a blank-identity option.
- D8, minor: the record and code disagree. `docs/components/Avatar.md:10` lists `accent`, which `Avatar.qml` never reads (the ring fill is `Style.text`, `Avatar.qml:43`). Line 11 says the dot "settles without animation", but `Badge.qml:64-66` animates its colour. Line 9 omits the public properties listed above. Fix: correct lines 9-11 in place; this section does not rewrite the existing record.
- SC1, medium (source conflict, owner decides): the presence contract shows two states on one dot. `Avatar.qml:37-38` says `status` names a tone, and the unit offers online (success) and away (warning) (`workbench/units/Avatar.qml:39-40`). `Badge.qml:25-26` says a dot is "never for a state a person has to distinguish from another state". The two dots have a luminance ratio of 1.03:1 (hand-computed), so they differ by hue alone. Whether colour-only meaning fails a criterion is a11y-audit's call (1.4.1).

### Redesign proposals

- P1: define the blank identity. A blank disc is the state a row shows for an unnamed person. The record forbids a silhouette glyph for a person, so the owner chooses between a blank disc, a neutral mark, or a text label supplied by the host.
- P2: a halo in the band colour under the presence dot would separate it from the photo by value, as ui-design asks, rather than by a stroke. Taste; the owner decides.
- P3: presence. If the owner keeps two states, each needs a non-colour cue (a shape or text in the host row). If not, the dot is one "present" signal.

### Source conflicts (not Avatar's to resolve)


### Hypotheses (observed in code, not measured)

- H1: a photo change shows the initials or glyph while `Image.Loading` (`Avatar.qml:108, 116, 151`; `asynchronous: true` at `:136`), so every change of source may flash the placeholder. Not measured.
- H2: initials use `charAt(0)` (`Avatar.qml:79-80`), which is a UTF-16 code unit. A name starting with an astral-plane character would yield a lone surrogate, rendered as a box. Not tested.
- H3: `StatRing` exposes an empty StaticText while ringed (`StatRing.qml:49-52`, visible via `Avatar.qml:90`), so a screen reader meets an unnamed node and not the progress. a11y-audit decides; run it for this surface.
- H4: Avatar's implicit width is `art + 2 × (2 + stroke)`; a host wrapper sized `art + 2 × stroke` keeps the ring inside only when `stroke >= 8`.

### Not examined

Runtime capture and live geometry (none run, by instruction). The reduced-motion clamp in `Motion.qml`. `Prose.qml` beyond line 80. The caelestia comparison: there is no Avatar file in `~/Clonned/caelestia/repo/components/controls/`, and the other caelestia folders were not searched. Keyboard and screen-reader criteria are a11y-audit's and were not run.

### Fixes

Source-reviewed and load-checked (`avatar` story loads, no QML error, dot seen straddling the rim at md); none owner-accepted.

- D1 fixed: the dot is `Style.rhythm(size * 0.2)` (8 at md, 12 at lg) and centred on the 45-degree rim point, so it straddles the edge at every size and on a rounded square. With a ring on, the dot sits over the ring's inner edge; not measured.
- D2 fixed: initials through `Style.textNear`, the glyph through `Style.iconNear`.
- D4 fixed in Avatar: `_ringRoom` is derived from the ring's inner edge using `StatRing._strokeInset`, each side rounded to a whole pixel, so the air is about 2.5 px at md and 2.25 px at lg. The ringed implicit size grows from 48 to 50 at md (62 to 64 at lg), so a host that sized a wrapper from the old number must follow. StatRing's own inset is untouched.
- D7 fixed in the unit: identity has `photo` and `blank`. No image ships with the library, so the photo is an inline SVG drawn from `Style` colours; whether `Image` decodes that data URL was not run, it needs one look in the live preview.
- D8 fixed: lines 9-11 and the property list match the code.
- SC1 open, owner ruling: `Badge` ignores `tone` for a dot (`Badge.qml:46`, always `textMuted`), so `status: "success"` and `"warning"` render the same neutral dot today, as the capture shows. The unit's online and away options are therefore indistinguishable. Either `Badge` gives the dot a tone and a non-colour cue is added, or `status` becomes one presence signal.
