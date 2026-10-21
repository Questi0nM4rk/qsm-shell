# ScrollCue

`ScrollCue` is non-interactive position furniture for a host `Flickable`.
It paints nothing when content fits; fades show only beyond the relevant edge.

states: hidden, resting, moving
inputs: `view`, `orientation`, `fade`, `fadeColor`, `indicator`, `fadeDepth`
tokens: `space5`, `space6`, `spaceTight`, `markThickness`, `surface`, `textMuted`
motion: `Motion.medium` mark opacity only
not designed: scrolling input, dragging, ticks, or a gauge

## UIX audit

Evidence: source-reviewed only. No capture, no live geometry, no runtime run, no owner acceptance.
Channels used: source (file:line below), tokens (`tokens/deep-night.json`, `qml/QsmShell/Style/Tokens.qml`),
and the caelestia sibling
(`~/Clonned/caelestia/repo/components/controls/StyledScrollBar.qml`). Contrast and pointer numbers are
computed from token values, not from rendered pixels.

### Purpose and consequence

The cue says that a viewport holds more content past one edge and where the view sits along it. A failure
costs a person either rows they never see, because they think the list ends, or a scroll affordance on
content that fits, where the interface claims more than it has.

### Controls, states, implementation

- Public properties: `view`, `orientation`, `fade`, `fadeColor`, `indicator`, `fadeDepth` (ScrollCue.qml:28-39).
- States: fits or overflows (ScrollCue.qml:56); at start, middle and end on each axis; moving or resting
  (:80); fade on or off; indicator on or off; vertical or horizontal.
- Implemented: every state above is derived in the component. The unit's controls cover content
  (overflowing, fitting), fade and indicator (workbench/units/ScrollCue.qml:45-58). Orientation is not
  reachable from the unit (D2).
- Catalog: one key, `scroll-cue` (workbench/stories.json:1080-1095). No fitting key and no horizontal key.

### Routes

- Pointer: none by design. `enabled: false` (ScrollCue.qml:61) lets the host Flickable receive the pointer
  and the wheel. Source only; not driven.
- Keyboard and focus: none. The host owns focus, and a non-interactive item has no focus route.
- Screen reader: no role and no name; the cue is decorative. Whether the list position must reach assistive
  technology is a11y-audit's question.

### Sizes, content, failure, cancellation

- Mark length clamps to [`space5` = 24, `space6` x 2 = 64] (ScrollCue.qml:66-67). Thickness `Style.stroke(markThickness)`: 3, snapped
  to whole device pixels. Inset `spaceTight` = 2 (:72-73).
- Fade depth defaults to `space6` x 2 = 64 (:39).
- Mark travel: offset = clamp(at / (1 - ratio), 0, 1) x (span - length) (:68-69). This maps the scroll
  fraction across the track; checked by hand, not run.
- Fitting or empty content: the mark is hidden by `overflows` (:71); the bottom fade by
  `_at + _ratio < 0.9999` (:117). The top fade has no `overflows` gate (H1).
- Long content: the mark stops growing at the 64 px cap; position still spans the full track.
- Failure: `view` is `required` (:28). There is no async work, so nothing to cancel.

### Visual roles and palette pairs

- Mark: `textMuted` at opacity 0.6 when moving, 0.2 at rest (ScrollCue.qml:77, :80-81; Tokens.qml:76-77).
- Fade: `fadeColor` to transparent, fully opaque over the first 30 % (:107-109, :120-122). Default
  `Style.surface` (:33).
- Computed from tokens, WCAG relative luminance, alpha blended over the unit ground `band` #271e30:
  mark at rest 1.56:1; mark when moving 4.02:1; `textMuted` on `band` 8.61:1; `surface` on `band` 1.30:1.

### Motion and reduced motion

- Mark opacity: `Behavior on opacity` with `Motion.medium` (ScrollCue.qml:83-84). That is Tokens.motionMedium
  = 260 ms (Tokens.qml:50) with `Motion.standardEasing` = `Easing.OutCubic` (Motion.qml:120). Reduced motion
  gives 100 ms (Motion.qml:58): shorter, opacity kept, which matches the duration rule.
- Fades: no transition. Their `visible` toggles at a threshold (:104, :117), so they appear and disappear in
  one frame. See S2.
- Measured timeline: none. The verdict on timing belongs to review-animations and is not issued here.

### Pointer geometry

- Input shape: none (`enabled: false`). Painted: the mark is 3 px across and 24 to 64 px along; each fade
  spans the whole viewport edge, 64 px deep.
- Assumption: there is no designed target. The record says "not designed: dragging" (line 10 above). The
  figures below are for a hypothetical grab of the rest-position mark, to show what a route that does not
  exist would cost.
- Viewport: unit 380 - 2 x 16 = 348 px square (workbench/units/ScrollCue.qml:18-19, :24).
- Origin assumption: the pointer starts at the viewport centre (174, 174). The target centre is the rest mark
  at x 344.5, y 32 (length at its 64 px cap; 16 rows x 40 px = 640 px content, ratio 0.544).
  Weights: uniform. There are no label origins or weights in the component.
- Distance D = 221.9 px (horizontal part alone 170.5 px).
- Width model: Shannon ID = log2(1 + D / W).
  - W = 3 px, painted width: ID = 6.23 bits.
  - W = 24 px, the pointer floor from ux-audit check 3: ID = 3.36 bits.
- Landing tolerance: plus or minus 1.5 px on the painted width; plus or minus 12 px at the 24 px floor.
- Neighbour interference: the mark sits over the host's rows at the right edge (:72). Because the cue takes no
  input, the row targets beneath remain the only targets. None recorded.
- Popup corridor and timing: not applicable.

### Findings

#### Defects

- D1 (minor, BACKLOG R2/R3): the horizontal case is not reachable in the unit or the catalog.
  - Evidence: the unit's `ListView` is vertical only and has no orientation property (workbench/units/ScrollCue.qml:21-27).
    Its controls have no axis group (:45-58). The sibling ScrollArea unit has an `axis` control and an
    `orientation` property. stories.json holds one key, with no horizontal and no fitting key
    (workbench/stories.json:1080-1095). A host with a horizontal list uses the horizontal cue.
  - Person sees: in the catalog, the horizontal axis cannot be looked at, and the fitting
    case has no story key, so a regression there passes unseen.
  - Fix: give the unit an `orientation` and a horizontal scroll host, as the ScrollArea unit does; add an `axis`
    control; add story keys for horizontal and fitting. shared = true (stories.json).

- D2 (polish): two cues on one view meet at the far corner.
  - Evidence: the vertical mark occupies x in [W - 5, W - 2] (ScrollCue.qml:72); the horizontal mark occupies
    y in [H - 5, H - 2] (:73). Both are at opacity 0.6 (:81). Where both reach their far ends, the 3 x 3 px
    overlap composes to 0.6 + 0.6 x 0.4 = 0.84. This applies only if the view overflows on both axes, which
    the consumer's content extent was not read to confirm.
  - Person sees: a small darker square in the bottom-right corner of the panel at full scroll on both axes.
  - Fix: a host with both cues hides the vertical cue's indicator while the horizontal one is overflowing.

#### Proposals

- P1, default ground: the library default (ScrollCue.qml:33, and the same default in ScrollArea) is
  `Style.surface`, the ground of a card rather than of the band most lists sit on. Options: default to `Style.band`, or make `fadeColor`
  required so each host names its ground, which the comment at ScrollCue.qml:30-32 argues for. Owner decision.
- P2, hold before the dim: the caelestia StyledScrollBar keeps itself up for a 600 ms hold after movement stops
  (`hideDelay` interval 600) and uses the same 0.6 active opacity. ScrollCue.qml:80-81 drops to 0.2 as soon as
  `moving` ends. Proposal: a hold before the mark dims. The verdict is review-animations'.
- P3, rest visibility: at rest the mark is 1.56:1 (computed). The comment at ScrollCue.qml:78-79 makes "nearly
  gone" deliberate, and the fade is then the only rest affordance. Owner decision whether to keep it; do not
  raise the value without that decision.

#### Hypotheses

- H1: the top fade gate is `_at > 0.0001` (ScrollCue.qml:104) with no `overflows` check, unlike the mark
  (:71). Fitting content stays fitting only if Flickable reports `yPosition` 0 for it. Unmeasured.
- H2: a zero-height host with content. `_ratio` is 0, so `overflows` is true, and the bottom fade at
  y = height - fadeDepth = -64 (:116) paints 64 px above the viewport. The cue is a sibling of the view (:58), so
  the view's clip does not contain it. A host that mirrors visibility by hand suggests the cue
  does not follow its view.
- H3: a viewport shorter than 24 px. The minimum mark length exceeds the track, so the offset goes negative
  (:68-69) and the mark leaves the viewport by the difference.
- H4: row text spans the full view width (workbench/units/ScrollCue.qml:31), so the 5 px strip at the right edge
  (ScrollCue.qml:72-73) may cover the last glyphs of long rows. Unmeasured.
- H5: the story declares viewport 800 x 500 (stories.json:1083-1086), while the unit's implicit size is 380 x 380
  (units:18-19). Which one the harness uses is unverified.

#### Not examined

- Runtime, captures and live geometry: none. No Workbench session, preview or capture was started, per the task.
- Themes: only the deep-night tokens were read. No light or high-contrast values.
- Motion: no timeline was measured; the verdict belongs to review-animations.
- Accessibility: names, focus and the 1.4.11 status of the rest mark are a11y-audit's. Not tested.
- Right-to-left: the horizontal leading and trailing edges use physical left and right (ScrollCue.qml:115,
  :121-122). Not examined for right-to-left layouts.
- Caelestia: one file compared (StyledScrollBar.qml). Caelestia has no edge fade, so the fade has no sibling to compare against.

### Evidence

- source-reviewed: every row above.
- runtime-exercised: none.
- owner-accepted: none.
