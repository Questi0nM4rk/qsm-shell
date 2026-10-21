# Kbd

A keyboard shortcut token group; a physical object the person knows from the world, so its key-cap border is one of the five a border may encode.
states: none; it is never hovered, pressed, focused, selected or disabled.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it describes keys but takes none and is never a tab stop.
screen reader: the combo text is the announcement; caps and joins are plain text roles.
size: each cap keeps at least a minimum width with fixed box insets; with no host width caps size to their content, and a host that gives a narrower width shrinks the caps and elides their text, the joins keep theirs.
tokens: spaceTight, space5, space2, space1, badgeHeight, radiusXs, overlay and textXs; no local colours or measurements.
motion: none.
not designed: input, shortcut handling or editing; it labels a shortcut the surface owns.

## UIX audit

Evidence: source-reviewed. No capture, tree dump, live geometry, pixel sample or window was taken,
and no owner check was made. Nothing here is runtime-exercised or owner-accepted. Contrast values
are computed from the deep-night token file and the `lift` algorithm in `Style.qml`, not sampled
from pixels. Sibling: caelestia has no keycap or kbd control under `components/controls/`.

### Purpose and consequence

Shows a shortcut as caps so a reader matches it to the keyboard. A wrong or unreadable cap sends the
reader to the wrong key. It labels a shortcut and takes no input.

### Controls and states

- Input: `combo` (required string). It splits on `+`, trims each part and drops empty parts
  (`Kbd.qml:21`, `Kbd.qml:29`).
- Public controls: none. The unit declares a `combo` group: short, modifiers, long.
- Valid states: the resting shape only. Hover, press, focus, selected and disabled are not defined.

### Routes

- Pointer: none. `Kbd.qml` has no MouseArea, HoverHandler, TapHandler or wheel handler, so events
  pass through.
- Keyboard: none. Not a tab stop, no `activeFocusOnTab`.
- Accessibility: `Kbd.qml` sets no `Accessible.*` property. The host supplies the name
  (role `StaticText`, name the combo text). A consumer that does not gets no combined name. Criteria are a11y-audit's.
- Programmatic: none.

### Sizes, empty, long and failure

- Cap width: `max(minCapWidth, text + space2)`, with `minCapWidth` = `space5` = 24 (`Kbd.qml:24`,
  `Kbd.qml:45`).
- Cap height: `badgeHeight + space1` = 16 + 4 = 20 (`Kbd.qml:46`; deep-night `geometryBadgeHeight`
  16, `space.1` 4).
- Cap text: Prose role `reading`, size overridden to `textXs` = 10 (`Kbd.qml:54`), weight from
  `Style.weightBold`, which falls back to `Font.DemiBold` (`Style.qml:216`). Separator: Prose role
  `metadata`, `textXs`, muted.
- Join spacing: `spaceTight` = 2 (`Kbd.qml:26`, `Kbd.qml:37`).
- Empty: a `combo` of `""` or of only `+` yields no parts. Kbd renders at zero size with no
  placeholder. Not designed.
- Long: Kbd takes the width its host gives it. Caps shrink to `space5` and their text elides; the joins keep
  their width. The bound applies once the host sets Kbd's `width`; until then it grows to its natural width.
- Failure: a malformed bind is repaired silently by the filter (`Kbd.qml:29`): `SUPER ++ Q` renders
  as `SUPER + Q`, and nothing reports it.
- Cancellation: none. No asynchronous work.

### Visual roles and palette pairs

- Cap text on cap fill: `text` on `keycap` = 7.2:1 (computed; 4.5:1 is the body-text line, 1.4.3).
- Separator on band: `textMuted` on `band` = 8.6:1 (computed).
- Cap fill on band: `keycap` on `band` = 1.90:1 (computed). The cap boundary carries no meaning
  the text does not, so 1.4.11 is a11y-audit's call.
- Border: none in `Kbd.qml`. The record's border claim is not met by code (SC-1).
- Motion: none. `Kbd.qml` has no Behavior, Transition or Animation, so review-animations has
  nothing to judge. Reduced motion does not apply.

### Pointer geometry

- Input shape: none. Painted cap: at least 24 px wide by 20 px tall.
- D, W and ID: not defined. Without a target there is no travel distance D and no landing zone W,
  so ID = log2(1 + D/W) is not computed.
- Width model, if a cap ever becomes a target (hypothesis): W is the short side, 20 px. The
  pointer 2.5.8 floor is 24 by 24 px (ux-audit), so a bare cap falls short on height.
- Origin assumptions: none needed.
- Popup corridor and timing: not applicable; Kbd is not a popup.
- Neighbouring interference: none; there is no target.

### Findings

Visual and layout (ui-audit):

| id | pass | element | evidence (source, computed) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| KBD-D1 | token | cap fill | `Style.qml:58` `keycap = lift(band, 0.9)`, computed 1.90:1 on band; fill #524a5a. Deep-night `overlay` is #4c4357 (`tokens/deep-night.json`). `Style.qml:146-147` says "No role is derived from it" | AGENTS surface ladder: three steps, nothing derived | a fourth, derived fill; this record (line 10) names `overlay`, the code uses `keycap` (`Kbd.qml:48`) | minor |
| KBD-D2 | accessibility name | root | `Kbd.qml` has no `Accessible.*`; the host sets the name | record line 8: "the combo text is the announcement" | the type announces nothing by itself | minor (name and role are a11y-audit's to rule on) |

Source conflicts:

- SC-1: this record, line 3, says the key-cap border is "one of the five a border may encode".
  AGENTS.md, "Surface ladder and borders", lists four, and `Kbd.qml` draws no border. Code and
  AGENTS agree; the record is the outlier. Remove the clause.
- SC-2: this record, line 9, says caps "size to their content". AGENTS DoD 5 forbids that for a
  component. The record states a behaviour the binding law rules out.

Redesign proposals (no fix committed):

- P2: choose the fill. `Style.overlay` is a ladder role and sits at 1.90:1 on band, the same as
  `keycap`. Use it and drop the derived token, or keep the step as a named role. Owner's call.
- P3: `Kbd.qml:54` overrides Prose's reading size (`textSm` by default, `Prose.qml`) with `textXs`.
  Name the 10 px cap as Kbd's decision, or add a role. Prose's header says a role states the
  decision once.
- P4: malformed binds. Decide whether Kbd keeps the silent repair (`Kbd.qml:29`) or reports it. The
  library's one-path rule argues against silent repair.
- P5: set `Accessible.name: root.combo` on the root so the host wrapper need not duplicate it.
  a11y-audit to judge.
- P6: sizing. Kbd has no size preset, so caps stay 20 px when a consumer scales text. Decide whether
  Kbd is a sized type under AGENTS "one scale per instance".

Hypotheses (unmeasured):

- H1: cap glyphs may sit off the cap's vertical middle. `Kbd.qml:50-52` centres the text box, and
  its leading and descent space shift the uppercase glyphs. Needs a zoom crop of one cap in a real
  window.
- H2: the `+` separator's vertical position depends on RowLayout's default alignment, which
  `Kbd.qml:39-43` does not set. It may sit off the cap's centre. Needs a tree dump.
- H3: whether shipped binds exceed 202 px cannot be computed without font metrics for
  10 px DemiBold. Needs the measured width of the longest real bind.

Not examined:

- Runtime: no capture, tree dump, live geometry, pixel sample or window. Each needs an explicit request.
- Themes and variants: only the deep-night token file was read. Light, high-contrast, scale factor
  and locale were not read.
- A host's rendering of a cheat sheet: not run.
- Accessibility tree, focus and keyboard routes: a11y-audit's.
- Motion: none exists to review.
