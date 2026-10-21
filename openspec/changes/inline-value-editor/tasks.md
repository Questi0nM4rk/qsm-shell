## 1. Contract

- [x] 1.1 Revise ListRow and Slider records before source changes, including fixed heading/editor clip ownership, focus round-trip, host state and shared N/O bindings.

## 2. Shell controls

- [x] 2.1 Add shared decrease/increase defaults to Interaction and per-instance Slider overrides; route custom keys through existing value/commit functions with shortcut and focus guards, and expose one live keyPressed hook for host navigation before template processing.
- [x] 2.2 Add host-controlled expandedContent to ListRow with fixed heading input/paint and clipped full-size content; preserve existing trailing/leading slots and immediately disable closed input.

## 3. Owner example

- [x] 3.1 Extend the existing ListRow unit with one adjustable Output volume purpose and repeatable mute neighbor, real focus/navigation, named actions and outcomes; preserve existing story variants.
- [x] 3.2 Add one catalog entry for this unit variant and reachable size, unavailable, boundary, custom-binding and empty-content cases; expose real native targets without touching Workbench core.

## 4. Requested checks

- [x] 4.1 Add one real QML hosted-input check for repeated Enter, editor open/adjust/close, retained selection/value, N/O and remapping, text entry, disabled/collapsed refusal and pointer routing. Extend only the affected Slider behavioral check where needed.
- [x] 4.2 Run this focused check and existing Slider/ListRow checks offscreen through installed Qt6 scripts, plus the affected installed-Workbench list-row-target flow; resolve failures in owning files, validate this change strictly and record evidence limits.

## 5. Owner checkpoint

- [x] 5.1 Hand over the initial adjustable-row example for feedback; the owner's requested replacement is the menu composition below, not acceptance of that example.

## 6. Menu composition revision

- [x] 6.1 Revise the Menu/ListRow records for the owner's menu composition, attached geometry and Up/Down editor navigation before source changes.
- [x] 6.2 Repair Menu's vertical natural layout, visible/selectable stepping and shared row activation; expose row identity access without a second selector.
- [x] 6.3 Register menu-items.json in the shell provider's Compositions section, backed by one native menu fixture with volume, mute/ON-OFF, Wi-Fi password/open network, Bluetooth/BLE, secondary actions and nonselectable rows; remove the two-item selector and its component-story entry.
- [x] 6.4 Tighten ListRow's generic editor slot to its text column, without duplicate control labels, preserving focus clearance and reduced motion.
- [x] 6.5 Move the affected hosted-input checks to this composition and exercise Up/Down, radio dependencies, password input/retry and cancelled reset along the same requested targeted check; previous green results do not establish current behavior.
- [x] 6.6 Replace only our old preview with this composition on workspace 10 and hand it back for owner judgement.
- [x] 6.7 Owner approves the revised menu composition as the boundary for proceeding to desktop output-volume/mute adoption. Archive remains separate.

The owner explicitly changed the example boundary from a ListRow variant to a
Menu composition. Additional write scope is Menu.qml, docs/components/Menu.md,
workbench/compositions/MenuInteractions.qml and menu-items.json, one fixture
registration in CompositionNode.qml and composition-types.json, the old catalog
entry and the existing hosted-input check. External Workbench runtime, shaders,
desktop code and unrelated dirty work remain untouched. Implement inline;
previous delegation and check results are not a prescription for this revision.

Pointer diagnosis of the new composition showed Flow's implicit height still
wrapped every row into a different column, putting controls outside the viewport.
Use a one-column/one-row Grid instead. Deferred layout/editor work uses
fixture-owned zero-interval timers so scene reconstruction cancels it rather
than evaluating stale Qt.callLater callbacks after their QML context is destroyed.

Strategy B, one sequential implementation segment with a Luna high worker and
requested Luna medium runner. No TDD, full suite, captures, audits, production
restart, live-device mutation, new backend, commit or archive. No structural
baseline exists; structural gating is skipped without creating/resetting one.

Implementation file boundaries: qml/QsmShell/Components/{ListRow,Slider}.qml,
qml/QsmShell/Style/Interaction.qml, docs/components/{ListRow,Slider}.md,
workbench/units/ListRow.qml, one entry in workbench/stories.json,
tests/units/tst_InlineValueEditor.qml and affected behavioral additions in
tests/units/tst_Slider.qml. Workbench core/Adapter, Menu, shader, desktop and
all unrelated dirty work remain readonly. Main owns change artifacts/task state.
The affected workbench/flows/list-row-target.json may drop its obsolete
successful-dispatch expectation for a report-only action; input refusal remains
checked through its existing handled key route and current result state.

## Deviations

The focused Qt run showed the native RangeSlider consumes Tab before the
ancestor host sees it. Add the same live-event interception seam TextField uses,
not a unit replacement for Slider's key dispatcher. Unsupported Qt Accessible
expanded-property syntax is removed; Expanded/Collapsed description remains.
Thumb focus handlers use Connections rather than invalid id-group assignments.
The existing row checks pass; other checks remain open until the current sources
run cleanly. No desktop or broader testing scope is added.

Receiver-level pointer diagnosis found the selected Slider's existing press
pre-jump changed its Qt value without emitting moved; a stationary click therefore
never updated the controlled host. Fix that missing intent in Slider, not the
unit's value-change handler. Tab interception belongs on the actually focused
thumb before its template handles navigation; root and thumb share one host hook
without duplicate reporting. These fixes remain within this item's input route.

## Evidence scope

Current Qt6 offscreen results: InlineValueEditor 11/11, Slider 38/38, ListRow
15/15; installed Workbench list-row-target flow passes 37 steps. Logs are under
`/tmp/opencode/inline-value-editor-checks/verified/`. No Qt warnings remain.
Actual key/pointer input covers the hosted operation, focus round-trip, retained
identity, search text/navigation, shared/per-instance bindings, vertical/range
nudges, interrupted held input and stationary click intent/commit.

The worker handoff `implementer.inline-value-editor.inline-row` passed its output
contract; main source review and Qt runs then corrected its compile/input gaps.
That contract proves handoff shape, not behavior. Main integrated those fixes in
the current working tree; no commit, release or archive was made.

The story `inline-value-editor` (ListRow / Adjustable value) is prepared for live
review no longer: it is replaced by shell Compositions / menu-items. The native
composition input check after the Grid repair passes 15/15, including pointer
value/commit and radio toggle, password typing/retry, editor Up/Down, and cancelled
BLE reset. Log: `/tmp/opencode/menu-composition-final-1791558666201070675/InlineValueEditor.log`.
The other affected checks pass Slider 38/38 and ListRow 15/15 under
`/tmp/opencode/menu-composition-checks-1791558244734369844/`; Slider/ListRow sources
are unchanged since that run. Explicit cancellation of a pending Wi-Fi connection
on closing its form is source-reviewed; reset cancellation is runtime exercised.

The installed Workbench loads menu-items.json in composition mode, confirms the
qsm-shell provider and readiness, and publishes menu-items in its Compositions
catalog. The current preview's startup log has no warnings; the older fixture's
deferred-context warnings are resolved by cancellation-owned timers. Owner
judgement permits the bounded desktop audio segment. Actual key auto-repeat timing,
screen-reader speech and production desktop selection retention remain unverified.
Consumer adoption is tracked by the consumer; it reuses existing services without changing live hardware. Only our owned shell preview sessions were replaced;
a consumer's existing preview is not part of this work.
