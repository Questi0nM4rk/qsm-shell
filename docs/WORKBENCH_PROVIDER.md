# Workbench Provider

`qsm-shell` is a workbench provider, not a preview application. Its production
QML stays in `qml/QsmShell/`; story units, the catalog and the adapter move
under `workbench/`.

Workbench is verification infrastructure. Component behaviour, composability
and native visual quality take priority over improving the harness chrome.

Prepare one coherent item, explain its task and supported states, then let the
owner inspect it. Correct the same item from feedback until accepted. Tests,
flows, captures and automatic input are tools the owner may request, not an
autonomous review loop. A rendered story is available, not accepted.

`workbench/` owns the manifest, catalog, adapter, descriptor, theme and
adapter-local story support. It has no window or catalog UI: the workbench owns
the catalog, the control strip, the scene switch and the tree dump, and the
provider's contribution is an adapter hosting one catalog unit or one
composition tree.

## Provider/units concrete requirements

- **Units**: `workbench/units/<Type>.qml` hosts every intent and exposes coherent
  examples and supported property states for the owner to inspect. One file per
  TYPE, PascalCase, mapped 1:1 with `workbench/stories.json` keys.
- **Action/event identity**: each unit's `integration` object (`events`,
  `actions`, `observables`, `runAction`, `keys`, `textDriver`, `checkpoints`)
  declares every name in kebab-case matched exactly. `kind` denotes distinct
  semantic component, not shared visual template; instance identity is separate
  (app rows share `app` type). Title does not fix missing identity. —
  `../qsm-workbench/docs/interaction-contract.md#identity-and-provenance`
- **Route completeness**: events keep `origin` (`component`, `injected`, `route`)
  separate from a unit's intent `kind`. An unknown node is refused, never served
  by the root. A step can never exercise the wrong node: the host refuses the
  step and names the node.
- **Schema before rendering**: normalize display once at ingress, typed
  required/optional fields, preserve original `identity/provenance/node`
  metadata, omit missing optionals not `String('undefined')` or made-up success.
  — `../qsm-workbench/docs/interaction-contract.md#event-boundary`
- Provider task declarations name only fixed validation, capture and flow
  operations, never a command, path or expression. Declaring these capabilities
  does not authorize running them without an owner request.

Two things the catalog is the single place for: a story's `unit` names the
harness that shows it, and the launcher resolves it to an absolute URL rather
than re-deriving where a file lives. A provider that owns a directory of
components declares `sourceRoot`; every type here is reachable from the
catalog, with no `uncovered` exceptions.

Composition starters live in `workbench/compositions/`; flow targets such as
`compositions/form-pair.json` resolve under this provider's `workbench/`.
`CompositionScene` renders the descriptor's static type mapping and routes
named links. The adapter exposes `integrationForNode`, `controlsForNode`,
`actionsForNode`, `applyNodeControl`, `triggerNodeAction` and `emitNodeEvent`;
an unknown node is refused, never served by the root. Events keep `origin`
(`component`, `injected`, `route`) separate from a unit's intent `kind`.

The flow state machine is the harness's, and so are the tests for it. A
provider shipping a copy is a provider whose green tests test the copy.

## Preview environment

`openspec/changes/fullscreen-capsule-composition/` defines the next provider work;
the matching harness contract is
`../qsm-workbench/openspec/changes/fullscreen-preview-environment/`.
Context forwarding and the neutral base are implemented; capsule Compose remains
pending the base's owner review.

The harness injects read-only `previewEnvironment` (`fullscreen`, logical
`screenRect`, `source: simulated`) into both story and composition paths. The
provider forwards it without recreating content or owning the mode toggle.
The shell mock fixture owns frame/available-space/placement policy. Actual window
fullscreen, canvas zoom and simulated application fullscreen are independent.

DataCapsule's unit is a neutral base, reviewed first. Sound will move to a real
Compose starter with independently addressable capsule/Slider nodes and declared
links. Both use one shared mock screen and placement rule. No new provider or
production service integration belongs to this work.
