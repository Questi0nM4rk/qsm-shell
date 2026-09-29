# Workbench Provider

`qsm-shell` is a workbench provider, not a preview application. Its production
QML stays in `qml/QsmShell/`; local story hosts, composition mappings, flow
hosts, and provider task declarations move under `workbench/`.

The provider renders real components through a fixed trusted adapter. Its
catalog and composition documents are data-only; only adapter code maps a
declared story or type to QML. It exposes explicit controls, actions, semantic
events, observables, and bounded input drivers to workbench.

`workbench/` is the provider boundary. It owns the manifest, story catalog,
adapter, composition descriptor, flow host, theme fixture, and adapter-local
story support. Shell npm preview and capture commands delegate to the sibling
generic workbench with `--provider` pointing at this repository.

Provider task declarations name only fixed validation, capture, and flow
operations. They never carry a shell command, arbitrary QML path, JavaScript,
or import.

## The layer split

A rule that lives in exactly one place must be written exactly once, and each
layer below may only read from the layer above it.

| layer | owns | may not |
| --- | --- | --- |
| harness | flow document language, runtime, result contract, artifact allocation | know any component |
| provider | story catalog, the `flow*` bridge surface, root type | decide a component's behaviour |
| story | the flow document, and a pointer-shaped injection point | re-derive a rule the component owns |

## What a provider must not do

- **Re-implement a rule the component already owns.** An adapter, story
  adapter and flow host exist to answer a component and drive its actions. The
  moment one decides a behaviour — when to close, what a grace period means —
  it has replaced the component, and a green flow proves only that the
  replacement works. Drive what the component reports; if it does not report
  what the host needs, the component is what is incomplete.
- **Claim a step type it cannot execute.** A step a host does not implement
  must FAIL and name itself. A fixture that returns success without doing
  anything is a lie: it converts a missing feature into a green check and
  hides every real gap behind it. The generic fixture faked four step types
  for exactly this reason.
- **Write a story name anywhere but the catalog.** Status, source and variant
  come from the catalog entry the host was given. An adapter that branches on
  a story key re-declares the catalog, and a second story reports `failed`
  with "unknown story".
- **Declare a control group twice.** Names are derived from the declaration
  (`IntegrationBridge.canonicalControls`), lowercased with whitespace folded
  to dashes. A capability record written by hand is a list the adapter will
  never notice drifting from its own `controls`.
- **Ship a partial step language under a full one.** The validator accepts
  every step type the language defines. A host that implements six of
  thirteen is not a slower provider, it is a provider whose preflight must
  fail closed on the other seven and say which.

## The flow host

The state machine belongs to the harness. A provider ships a host only when it
needs a different root type or runtime — a `ShellRoot` under `quickshell
--path` rather than an `Item` under `qml` — and then it implements the whole
step language or it does not claim the capability. A reduced host is the
failure this contract exists to prevent: it is indistinguishable from a
complete one to every automated check, so the reduction is never reported.
