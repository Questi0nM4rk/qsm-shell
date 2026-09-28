# Workbench Provider

`qsm-shell` is a workbench provider, not a preview application. Its production
QML stays in `qml/QsmShell/`; local story hosts, composition mappings, flow
hosts, and provider task declarations move under `workbench/`.

The provider renders real qsm-shell components through a fixed trusted adapter.
Its catalog and composition documents are data-only; only adapter code maps a
declared story or type to QML. It exposes explicit controls, actions, semantic
events, observables, and bounded input drivers to workbench.

`workbench/` is the provider boundary. It owns the manifest, story catalog,
adapter, composition descriptor, flow host, theme fixture, and adapter-local
story support. Shell npm preview and capture commands delegate to the sibling
generic workbench with `--provider` pointing at this repository.

Provider task declarations name only fixed validation, capture, and flow
operations. They never carry a shell command, arbitrary QML path, JavaScript,
or import.
