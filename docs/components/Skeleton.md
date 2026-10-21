# Skeleton

A loading placeholder that holds the shape of content still arriving; it reserves space and never carries meaning.
states: block and line; a line takes its height from its Prose role and a pill radius, while a block uses the control height and small radius.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it claims no events and wheel passes through.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; it is a placeholder with no accessible name until real content lands.
size: width is a fraction of the control width and never content-derived; line height follows the role scale from hero to metadata.
tokens: controlHeight, controlWidth, radiusSm, overlay and the text scale; no local colours or measurements.
motion: an infinite opacity pulse while visible; reduced motion lengthens the period.
not designed: progress values, error copy or empty explanation; use ProgressBar, Callout or EmptyState for those.

## UIX audit

Channels: source only (`Skeleton.qml`, `workbench/units/Skeleton.qml`, `Prose.qml`, `Style.qml`,
`Motion.qml`, `Tokens.qml`, `tokens/deep-night.json`, the `skeleton` story and
`workbench/flows/skeleton-shape.json`). No live geometry, no capture, no running window. Evidence is
source-reviewed only: nothing here is runtime-exercised or owner-accepted. Themes: `deep-night` is the
only token set in the repository.

### Purpose and consequence

Stands in for content whose shape is known before its data arrives. The consequence it must hold is
that the surface keeps its size when the data lands (`Skeleton.qml` lines 1-10). Where the shape is
unknown, the record says a `Spinner` is the honest type.

### Controls, states, routes

- Properties: `shape` (block, line), `role` (line only), `fraction` (width). All three are implemented
  (`Skeleton.qml` lines 21, 23, 26). The unit exposes them as `controls` (`workbench/units/Skeleton.qml`
  lines 45-61). Not implemented and not designed: a size preset, a busy state, a failed state.
- Valid states: block and line. The only motion state is the breath between opacity 1 and 0.4.
- Pointer: none. The item declares no handler, so it has no hit target; the wheel passes through.
- Keyboard and focus: none. It is not a tab stop and holds no focus.
- Screen reader: no `Accessible` properties are declared. The item is an unnamed generic `Rectangle`.
- Real routes named: none. This is a source fact, not a runtime one.

### Sizes, content, failure

- Block: width `Style.controlWidth` (380) times `fraction`, height `Style.controlHeight` (40), both
  fixed (`Skeleton.qml` lines 39, 45). The block does not follow the library's `sm` and `lg` control
  heights.
- Line: height is the role's pixel size, 10 to 44 px (lines 27-36); width as for block.
- Empty and long content: not applicable, the component holds no content.
- Failure and cancellation: none in the component. The breath runs until the consumer removes or hides
  it. There is no timeout, so a response that never comes leaves the placeholder breathing.

### Visual roles, palette pairs, motion

- Fill: `Style.overlay` (`Skeleton.qml` line 47), no border, no shadow, no local colour.
- Pairs computed from `tokens/deep-night.json` by WCAG relative luminance (inferred from the hex
  values, not sampled): overlay `#534a5e` on band `#271e30` 1.91:1; on surface `#42394c` 1.31:1.
  At the trough (opacity 0.4, blended toward the ground) 1.27:1 on band and 1.11:1 on surface.
  Ladder steps measured: band to surface 1.46:1, surface to overlay 1.31:1.
- Radius: a pill (height / 2) for lines, `Style.radiusSm` (8) for blocks.
- Motion: `SequentialAnimation` on `opacity`, 1 to 0.4 to 1, each half `Motion.pulse / 2`, period
  1400 ms (`Tokens.qml` line 67), easing `Motion.moveEasing` (InOutCubic), running while `root.visible`.
- Reduced motion: `Motion.pulse` doubles the period to 2800 ms. Opacity still animates; nothing moves.
- Measured: none. The period is the token value.

### Pointer geometry

- Input shape: none. No hit target exists, so D, W and ID (log2(1 + D/W)) are not applicable. There is
  no width model to state, no label origin and no label weight.
- Painted size: block up to 380 by 40 px; line 380 px wide at `fraction` 1, height by role.
- Neighbour interference: none. The item claims no events, so a neighbour's target under it is unchanged.
- Trigger-to-panel corridor: not applicable.

### Findings

Defects (source-backed, file and line cited):

- SK-1, `Skeleton.qml` line 39 with the role map at lines 27-36. A line placeholder is sized to the
  role's font pixel size. The real text is a `Text` with `lineHeight` set by `Prose.qml` line 102:
  `Style.lineBody` (1.55) for body, otherwise 1, which is a multiple of the font's natural line spacing.
  The placeholder therefore sits below the real line box, and the surface grows when the text lands,
  which is the thing the component exists to prevent. Body is the worst case: the placeholder is 12 px
  against an estimated 22 px line (assumed natural spacing 1.2, not measured). Estimates for the other
  roles: hero 44 vs about 53, display 28 vs about 34, heading 22 vs about 26, title 14 vs about 17,
  label 12 vs about 14. The role map also has no `section` case, so it falls to the default 12 px where
  `Prose.qml` line 78 uses 10 px. The record (`docs/components/Skeleton.md` line 4) says a line takes its
  height from its Prose role; the code does not, which is a source conflict with the record. Fix: one
  owner of a role's line box in `Style`, read by both `Prose` and `Skeleton`. Shared, because the fix
  touches `qml/QsmShell/Style/*`.
- SK-2 (fixed: the unit offers the role group only while `shape` is `line`; source-reviewed, load-checked, not owner-accepted), `workbench/units/Skeleton.qml` lines 50-57 as audited. The six `role` options are offered in every shape,
  but the component reads `role` only in the line state (line 39). In block state a person who clicks
  "hero" or "metadata" sees nothing change. Fix: show the role group only when `shape` is `line`, or
  say in the unit that it is inert in block. Not shared (unit file).

Proposals (taste, design, or consumer concerns):

- P1, size: a block of fixed 40 px under a 32 px `sm` control jumps 8 px on load. The library gives
  sized types a `size` preset (AGENTS law), and a placeholder that stands for a control should match
  its size. Option: a `size` preset read through `Style.size("Skeleton", size)`. Shared (tokens/Style).
- P2, literals: the trough `0.4` (`Skeleton.qml` line 55) is a number in a component (AGENTS: every
  number from `Style` or `Motion`), and the record's line "no local measurements" is wrong about it.
  A retheme cannot reach the trough. Option: a token. Shared (tokens and Style). Source-conflict:
  the record and the code disagree on this point.
- P3, integer width: `implicitWidth` (line 45) is not rounded. `fraction` 0.33 gives 125.4 px, a
  half-pixel right end. Option: `Math.round` on the product (qml-ui integer geometry rule). Visible
  effect is small on a soft placeholder.
- P4, trough contrast: the fill falls to 1.27:1 on band and 1.11:1 on surface at the trough. Whether
  that matters is an accessibility question for a11y-audit (1.4.11 turns on whether the shape carries
  meaning), and a design question for the owner. The numbers are above; no threshold is invented here.
- P5, count: the unit runs three independent loops at once (`workbench/units/Skeleton.qml` lines 26-40
  each start a `Skeleton`, and each runs lines 53-56). review-animations standard 4 flags more than one
  to two animated elements per view. Option: one owner for the breath, or animate only the lead line.
  The consumer count is unknown: no consumer exists (see Not examined).
- P6, finish path: the breath has no end and no failed or busy state. The header (lines 4-10) warns
  that a placeholder promising content that never comes is a lie. The consumer must hide it; the
  record should say so, and a consumer-level wait cap belongs to ux-audit check 9 in the host.
- P7, accessibility: a placeholder announces nothing. Any busy signal belongs on the consumer's
  container, not on the placeholder. Criteria are a11y-audit's.
- P8, side finding outside this file: AGENTS.md says the surface ladder steps are each 1.30:1 on the
  one below. The deep-night token values give band to surface 1.46:1 and surface to overlay 1.31:1.
  Source-conflict between the design sources; which one wins is the owner's ruling.
- P9, unit width: `width` (unit lines 58-61) changes only the lead line. The two other lines keep
  their fixed fractions, so "short" shortens one bar. Intended or not is the owner's call.

Hypotheses (observed in the source, not measured):

- H1: `running: root.visible` (line 53) reads the item's own `visible`. If an ancestor is hidden the
  loop may keep running off-screen, a cost and not a visible fault. Check: hide a parent in a live run
  and read the animation's `running` state.
- H2: the Prose line box of 1.2 times the font size is an assumption behind SK-1. Check: read the
  rendered `Text.height` of a `Prose` label in a live run and compare with `Skeleton.height`.

Verdict under review-animations (from code only; feel is not judged): standards 1, 2, 3, 5, 7 and 8
pass by source (a state indicator, an opacity-only loop, an eased breath, no transform, reduced motion
kept as opacity). Standard 4 is flagged in P5. Standard 6 does not apply to a loop with no input. Approve
from code, with the feel unjudged. The check that decides the feel: slow the period to 2 to 5 times in a
live window and watch the breath against the surrounding surface. Not run.

### Not examined

- No live window, no capture, no item-tree dump; so no measured geometry for any row.
- Themes: only `deep-night`. No light or high-contrast token set exists in the repository.
- Sizes `sm` and `lg`, since the component has no size preset (P1).
- Reduced motion at runtime.
- Keyboard, focus and screen reader routes: a11y-audit's method.
- Consumers: `qsm-desktop` has no `Skeleton` use (grep of `shell/` and the whole repository). Caelestia
  has no skeleton or shimmer file; its nearest sibling is `LoadingIndicator.qml`, a spinner, so no
  comparison of the placeholder is possible.
