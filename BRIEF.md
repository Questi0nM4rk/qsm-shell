# Finish The Generic Workbench Provider Migration

## Goal

Make this repository a complete provider consumed by the generic sibling
`qsm-workbench`. Remove the renamed legacy preview-unit architecture. The
workbench must render real `qml/QsmShell/Components` components, but the generic
workbench repository must not know anything about qsm-shell.

Read before editing:

- `AGENTS.md`
- `GOAL.md`
- `docs/WORKBENCH_PROVIDER.md`

Do not read sibling repository files; the provider contract required from them
is fully restated below. Sibling commands in the verifier are allowed.

## Hard Rules

- Edit only this `qsm-shell` repository.
- Preserve all unrelated dirty component changes. Never reset, checkout, or
  overwrite them.
- Use `apply_patch` for manual edits.
- Do not create a commit.
- Do not use OpenAI models or spawn subagents.
- No `previews/` runtime and no `workbench/units/` directory may remain.
- No separate per-type story QML files. Replace them with one data-driven
  `workbench/StoryHost.qml` containing a fixed allowlisted component factory.
- Exceptional Rollout, ScenePointer, and slot fixtures may be inline
  `Component` declarations in that one host.
- Stories use real production components. They own host state and answer every
  component intent; they never visually reimplement a component.
- `workbench/stories.json` must use `{ "version": 1, "stories": { ... } }`,
  contain no `unit` fields, and include catalog metadata now owned by provider.
- JSON may not contain QML paths used as Loader sources, JS, callbacks,
  expressions, commands, or arbitrary property paths.
- `Adapter.qml` directly hosts `StoryHost.qml` in story mode and
  `CompositionPreview.qml` in composition mode.
- `CompositionNode.qml` must not load `units/*.qml`; use fixed inline component
  mappings and preserve current composition controls/actions/events.
- Generic workbench owns the window, launch, capture and task supervision.
  Delete `LivePreview.qml`, `CapturePreview.qml`, and `CaptureComposition.qml`.
- `scripts/preview-qml.mjs` launches `../qsm-workbench/scripts/workbench.mjs`
  with `--provider` set to this repository.
- `scripts/capture-qml.mjs` and `scripts/capture-all` invoke declared generic
  workbench tasks through `../qsm-workbench/scripts/task-runner.mjs` with
  `QSM_WORKBENCH_PROVIDER_ROOT` set. Never invoke a shell command string.
- Keep production behavior tests. Remove source-shape/unit-walker tests. Update
  provider runtime tests to `workbench/` paths.
- Docs state only current truth; no migration history.

## Required Behavior

- Story controls and actions work through `applyControl()` and
  `triggerAction()`.
- Component intents are normalized through `eventRecorded(record)`.
- `dumpTree()` emits `inspectionReady(inspection)`.
- Reset reconstructs or resets host-owned story state.
- Current text-field semantic flow remains functional.
- Existing composition examples validate, render and capture.
- Unknown story/type/action/control fails truthfully.

## One Verifier

Run exactly this final verifier from this repository:

```bash
npm test && node ../qsm-workbench/scripts/workbench.mjs --provider "$PWD" --check && QSM_WORKBENCH_PROVIDER_ROOT="$PWD" node ../qsm-workbench/scripts/task-runner.mjs story-capture text-input /tmp/qsm-shell-text-input.png && QSM_WORKBENCH_PROVIDER_ROOT="$PWD" node ../qsm-workbench/scripts/task-runner.mjs flow ../qsm-workbench/flows/examples/text-field-clear-accept.json && QSM_WORKBENCH_PROVIDER_ROOT="$PWD" node ../qsm-workbench/scripts/task-runner.mjs composition-check ../qsm-workbench/compositions/examples/text-field-matrix.json && QSM_WORKBENCH_PROVIDER_ROOT="$PWD" node ../qsm-workbench/scripts/task-runner.mjs composition-capture ../qsm-workbench/compositions/examples/text-field-matrix.json /tmp/qsm-shell-text-field-matrix.png
```

## Finish Line

- Verifier exits zero.
- `workbench/units/` and `previews/` do not exist.
- No active QML, JS, package script, or test references either directory.
- Report changed/deleted files, verifier result, and any unmet behavior.
