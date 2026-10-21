# Section

A titled group with a heading action and a content column; the header labels the group and the action acts on it.
states: none; the header shows only while a title or an action exists, and an empty action takes no space.
actions: none of its own; the heading `action` slot and the default `content` slot belong to the consumer.
pointer: none on the group itself; slotted controls keep their own targets and wheel passes through.
keyboard: none on the group itself; slotted controls keep their own tab stops and keys.
screen reader: the section title labels the group; the action and content name themselves.
size: content-driven column; the group starts `space4` clear of what precedes it (a first section in a column takes `Layout.topMargin: 0`), its rows hang `space1` below the heading and `space1` apart; the heading row fills the width with the title taking the free space.
tokens: space1, space4 and Prose; no local colours or measurements.
motion: none.
not designed: collapsing, selection or scrolling; use Disclosure, Menu or ScrollArea for those.

## UIX audit

Evidence: source-reviewed only. No live tree, no capture, no runtime route, no owner acceptance.
Channels: live geometry not run; design source absent (no `design/` in this repo), so expected
values cite `qml/QsmShell/Style/Tokens.qml` defaults and `AGENTS.md`. Sibling: none in
`~/Clonned/caelestia/repo/components/` (a search for "section" matched nothing).

### Purpose and consequence

The group names a set of rows and puts one action on its heading, so the action sits where the
group is named. It is the wrong type for a collapsible, selectable or scrolling group.

### Controls and states

- Declared (`workbench/units/Section.qml:50-56`): header `titled` (title and action), `untitled`
  (action only), `bare` (neither).
- Implemented: header visibility is `visible` on the header row (`Section.qml:30`). With no title
  and no action the header takes no layout space.
- Not reported: the group has no enabled, selected or loading state. The action's states belong to
  Capsule (`Capsule.qml:73-99`).
- Empty body: the column is zero height; no empty message exists, which is the slot owner's job.

### Routes

- Pointer: none on the group. Section has no handler, so a wheel over it reaches the scroller
  behind (source absence, not driven).
- Keyboard: the heading action is the only tab stop; Capsule takes `Qt.StrongFocus` and answers
  Return, Enter and Space (`Capsule.qml:177-179`). Rows are static.
- Focus ring: drawn by StateLayer for keyboard focus only (`StateLayer.qml:64-72`). Section draws
  none.
- Accessibility: the action is `Accessible.Button` named by its label (`Capsule.qml:52-53`).
  Section and Prose set no Accessible property (grep: 0 matches), so the title does not label the
  group. See S-1.

### Sizes, long content, failure, cancellation

- Width: consumer-set. The unit uses `Style.controlWidth`, 380 (`Tokens.qml:86`; unit line 32).
- Height: the heading row is as tall as its tallest child. Title is role `section`, 10px
  (`Tokens.qml:35`), line height 1 (Prose sets line height for body only). Action is `sm`, 32px
  (`Capsule.qml:73`, `Tokens.qml:84`).
- Gaps: before the group 16px (`space4`); heading to body 4px and rows 4px (`space1`).
- Long title: NoWrap and ElideRight, so it elides only when its row is constrained. Its full width
  still counts toward the natural width. See S-2.
- Failure and cancellation: none. `Capsule.activate` is a no-op while disabled (`Capsule.qml:78-81`).

### Visual roles and palette pairs

Section paints nothing. The unit paints `Style.band` behind it (unit line 27). Ratios below are
WCAG relative luminance on the default `Tokens.qml` values, computed from source, not pixels:

| pair | ratio | requirement |
| --- | --- | --- |
| title, textMuted `#c5bad1` on band `#271e30` | 8.61:1 | 4.5 (1.4.3); 10px bold is not large text |
| ghost action label at rest (textMuted) on band | 8.61:1 | 4.5 |
| ghost action label on hover (text `#f0ecf5`) on band | 13.71:1 | 4.5 |
| hover body (surface at 0.9 opacity over band, `#3f3649`) with text | 9.82:1 | 4.5 |
| hover body with muted label | 6.17:1 | 4.5 |
| focus ring accent `#d9b4ea` on band | 8.87:1 | 3:1 (1.4.11) |

A ghost action paints nothing at rest (`Capsule.qml:97-99`), so its only resting cue is the muted
label. That is the intended ghost law, not a defect.

### Motion

None in Section: no `Behavior`, no animation. Micro transitions belong to Capsule and StateLayer
(`Capsule.qml:101-106`). Reduced motion has nothing to shorten here.

### Pointer geometry

Model, not measurement. Width model: Fitts' Shannon form, ID = log2(1 + D/W), with W the input
shape's extent along the approach axis.

- Input shape: the heading action's layout box, which StateLayer fills (`Capsule.qml:164-166`).
  Height 32px. Width = label + 2 x 12 (`contentInset`, `Capsule.qml:71`). Assumed label width 40px
  at 10px, so width about 64px.
- Painted: at rest only the label, assumed about 40 x 10px. The input shape is about five times
  the painted label area.
- Hover: StateLayer scales the capsule to 1.04 (`Tokens.qml:60`), so the input grows to about
  33 x 67px.
- Origin assumption: the pointer rests over the centre of the first row. The action is
  right-aligned in a 380px group, so its centre is at x 348; the row centre is at x 190. D = 158px.
  Label origin: left edge at the capsule's padding. Label weight: medium (role `label`), assumed.
- Vertical approach (W = 32): ID = log2(1 + 158/32) = 2.57 bits. Landing tolerance +/-16px
  (+/-16.6 hovered).
- Horizontal approach (W = 64): ID = log2(1 + 158/64) = 1.79 bits. Landing tolerance +/-32px.
- Neighbouring interference: no other target inside Section. A second slotted action sits 4px
  away (`Section.qml:41`): an overshoot of more than 4px past the first target's edge lands on it.
- Floors: 32px high and about 64px wide clear the 24px pointer floor from ux-audit check 3.
  They are under the 44px touch floor, which a pointer shell does not need. The 2.5.8 verdict is
  a11y-audit's.
- Popup corridor and timing: not applicable.

### Findings

Defects (source-backed, each with a concrete fix):

| id | pass | element | evidence (source-reviewed) | expected (source) | actual | severity |
| --- | --- | --- | --- | --- | --- | --- |
| S-1 (fixed, source-reviewed, load-checked) | structure; the criterion is a11y-audit's | group title | `Section.qml:16-37`; no Accessible property in Section or Prose | `Section.md:8`: the title labels the group | nothing names the group; the title is plain text to an assistive tool | minor |
| S-2 | geometry | group natural width | `Section.qml:33-37`: title Prose is `fillWidth` with no `Layout.preferredWidth`; its full text width counts toward the natural width | `Section.md:10`: long content elides, not grows | in a parent that sizes the group from its natural width, a long title widens the group past its column | minor |
| S-3 (fixed, source-reviewed, load-checked) | source rule (`AGENTS.md`, comments) | comment | `Section.qml:6-15` narrates the past and a consumer that no longer exists | comments explain non-obvious mechanics only | history in source; the one-consumer claim is unverified | minor |

Fixes: S-1 (fixed: `Accessible.Grouping` with `Accessible.name: root.title` on the root
ColumnLayout; screen-reader behaviour not driven). S-2, set
`Layout.preferredWidth: 0` on the title Prose at `Section.qml:34` and keep `fillWidth`, so the
title takes only the free space. S-3 (fixed: the history comment is deleted, the one mechanic stays). All three are in `Section.qml`; none needs a shared file. S-2 is open.

Proposals (taste and design, no defect claimed):

- P-2: the fixture's action name "Refresh" (unit line 19) names no group. With several groups on
  one screen, each reads as "Refresh". Consider the group in the label ("Refresh devices") or
  exposing the title as the action's description.
- P-3: two heading actions sit 4px apart (`Section.qml:41`), two 32px-high targets. Consider 8px
  for multi-action headings. No design-source threshold exists to cite.
- P-5: the title is 10px, uppercase, bold, tracked 1.4px (`Tokens.qml:35`, `:128`). It is the
  smallest text in the shell; the owner should judge legibility at 1x.
- P-6: an elided title has no full-text path (no tooltip, no wrap). A long group name loses its end
  without notice.

Hypotheses (unmeasured, never mixed into the table):

- H-1: the `bare` option assigns `null` to the list alias `action` (unit line 34, `Section.qml:21`).
  Whether that empties the `actionHost` that already holds the Capsule is not readable from source.
  If it does not, `bare` still shows Refresh. Check: tree dump of `actionHost` children after
  switching to `bare`.
- H-2: `Prose` has no alignment, while `actionHost` centres (`Section.qml:40`). If the title sits
  at the top, its centre is about 10px above the action's centre (32 minus about 12, halved).
  Check: tree positions of title and action.
- H-3: the observable `visible-children` (unit line 63) reads 2 for both `titled` and `untitled`,
  and 1 for `bare`, so it cannot tell a title from an action-only header.

Not examined:

- Live tree, captures, runtime routes: not run (no Workbench session in this task).
- Light theme: `Tokens.qml` has one dark set only.
- 200% text, reduced motion, high contrast: not driven.
- Multi-action header, empty body, long title rendering: source only.
- Keyboard and screen reader behaviour: a11y-audit's method, source reading only here.
- Owner's design intent: no design source in this repo.
