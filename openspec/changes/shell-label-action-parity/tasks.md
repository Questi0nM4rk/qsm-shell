## 1. Component contract

- [x] 1.1 Revise ControlLabel and Slider records before code: optional action task, keyboard/Tab/accessibility, cancellation, public identifiers, caption/disabled/empty cases, sizes and unchanged footprint.

## 2. Shared label route

- [x] 2.1 Implement ControlLabel's guarded boolean activate, named Action, actionable-only focus/Tab, keyboard activation/cancellation and accessibility press/name with StateLayer feedback.
- [x] 2.2 Add Slider.activateLabel, labelAccessibleName and appended activate-label Action; give existing actions stable identifiers and route the actual label through activateLabel without changing level/thumb behavior.

## 3. Fully hosted example

- [x] 3.1 Make Slider's existing unit answer label intent with a coherent mute example and expose truthful named actions/native targets and resulting state; retain its existing level/range cases.
- [x] 3.2 Route SoundChannel programmatic mute through Slider.activateLabel and expose Slider.labelItem directly; preserve level and existing component/route evidence.

## 4. Requested behavioral verification

- [x] 4.1 Extend existing ControlLabel and SoundChannel QML checks for actual Tab/Backtab, Enter/Return/Space, pointer/action routes, cancelled held activation and disabled/caption/empty refusal; update the existing Slider action-route check for the appended operation without preserving its obsolete static action-text assertion. No TDD or static/source-shape assertions.
- [x] 4.2 Run the focused label and sound checks plus affected existing Slider and provider flows through the installed tools; report source/runtime/owner evidence separately and validate this change strictly.

## 5. Owner handoff

- [ ] 5.1 Prepare the same label/mute operation through its companion desktop integration and hand over one item; wait for owner acceptance before another component.

Execution: Strategy B, sequential one-item segment. Main owns planning and task
state, a bounded Luna high worker owns implementation, and a bounded Luna medium
runner performs the requested checks. No parallel source writers, production
restart, live audio changes, commit, archive or whole-catalog sweep. Implementation
and verification tasks are checked only with the evidence they require; owner
handoff remains a separate checkpoint. No structural baseline exists: skip the
structural gate with an explicit note, never silently create or reset one.

File boundaries: implementation writes only ControlLabel.qml, Slider.qml, their
two component records, units/ControlLabel.qml, units/Slider.qml, fixtures/SoundChannel.qml,
and the existing tst_ControlLabel.qml/tst_SoundChannel.qml/tst_Slider.qml checks. One focused
label-action flow may be added under workbench/flows; the affected existing
slider-level.json may be corrected to assert disabled availability rather than
demand successful dispatch of a refused action. Workbench core, desktop
sources, shader and all unrelated component changes remain outside this segment.

## Deviations

The first focused run exposed an obsolete four-action assertion in the existing
Slider check; its file boundary is added for the smallest behavior-only update.
SoundChannel must retain its public descriptor array while using a separate
dispatch dictionary internally; changing it to an object breaks the existing
composition host. Mute evidence includes one component and one route event per
operation, not two component activations. Qt also warns when a focused label
loses Tab eligibility before it surrenders focus; correct that transition in the
owning label. These are integration/mechanical corrections, not scope expansion.

The corrected Slider unit now returns false for a refused disabled action. Its
existing level flow expected that dispatch to succeed while doing nothing;
update this affected flow to observe disabled availability. Actual disabled
input/API refusal remains exercised by the focused QML checks, not a fabricated
successful flow step. Installed flow invocations use absolute provider flow paths.

## Verification scope

ControlLabel 8/8, SoundChannel 8/8 and Slider 36/36 pass through Qt 6 offscreen;
slider-level 28 steps, slider-ods 20 steps and data-capsule-sound 28 steps pass
through installed Workbench. Logs: `/tmp/opencode/shell-label-action-checks/`.
Accessibility press routing and auto-repeat guards are source-reviewed; actual
screen-reader speech and native compositor focus are unverified. No owner
acceptance, production restart, real-device mutation or release is claimed.

## Active scope clarification

This segment repairs local keyboard/component-action parity only. The owner's
immediate goal is easy action-menu control and general keyboard navigation,
reusing existing service functions or external commands. No universal backend
API or wholesale view extraction is required. Keep this bounded keyboard repair
and its evidence; it does not complete the action menu or desktop-wide navigation.
