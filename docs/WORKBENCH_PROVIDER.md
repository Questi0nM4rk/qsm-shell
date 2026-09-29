# Workbench Provider

`qsm-shell` is a workbench provider, not a preview application. Its production
QML stays in `qml/QsmShell/`; story units, the catalog and the adapter move
under `workbench/`.

`workbench/` owns the manifest, catalog, adapter, descriptor, theme and
adapter-local story support. It has no window and no view: the workbench owns
the catalog, the control strip, the scene switch and the tree dump, and the
provider's whole contribution is an adapter that hosts one unit and forwards
that unit's contract. Provider task declarations name only fixed validation,
capture and flow operations, never a command, path or expression.

Two things the catalog is the single place for: a story's `unit` names the
harness that shows it, and the adapter resolves it to an absolute URL rather
than re-deriving where a file lives. A provider that owns a directory of
components declares `sourceRoot`; every type in it must be reachable from the
catalog or named in `uncovered`, so "the storybook holds every story" is
checked rather than remembered.

The flow state machine is the harness's, and so are the tests for it. A
provider shipping a copy is a provider whose green tests test the copy.
