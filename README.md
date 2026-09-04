# qsm-shell

Reusable QML components and design tokens extracted from qsm-desktop.

The project currently provides leaf components. It is not yet a complete
desktop shell and does not yet provide the shader-backed `ShellBorder` system.

## Use

Add `qml/` to the QML import path:

```qml
import qs.QsmShell.Components
import qs.QsmShell.Style

Card {
    width: 280
    height: 96
}
```

Public types are listed in `qml/QsmShell/Components/qmldir`. Desktop services,
state, persistence, and compositor behavior stay in the consuming application.

## Develop

```bash
npm run gallery
npm run capture -- capsule /tmp/capsule.png
npm test
```

- `gallery` starts the React design playground.
- `capture` renders one native QML preview offscreen to the requested PNG.
- `test` regenerates tokens, lints QML, runs the native QML smoke, and builds
  and lints the gallery.

Add visible behavior first. Verify it in native QML, then add one focused
regression check if the behavior can realistically regress.

## Next Milestones

1. Use a small leaf cohort from this library in qsm-desktop.
2. Port the existing shader unchanged.
3. Render one real `ShellBorder` with one dynamically anchored rollout.
4. Review that result live before adding nesting, welding, or fullscreen rules.
