# Backlog

## Next

- Import a small leaf-component cohort into qsm-desktop and verify it live.
- Audit each public component while it is touched; remove APIs that have no real
  consumer or behavior.
- Port the existing qsm-desktop edge shader unchanged.
- Implement one `ShellBorder` rendering one dynamically anchored rollout.
- Add nesting, welding, resizing, and fullscreen behavior one visible slice at
  a time after that first composition is accepted.

## Later

- Decide whether the divider needs vertical orientation after a real layout
  requires it.
- Add SVG aliases and validation only when the first naming conflict appears.
- Add a light theme only after its palette is designed and reviewed.

## Known Environment

- `/usr/bin/qmltestrunner` is Qt 5 and cannot test this Qt 6 module.
- Use `/usr/lib/qt6/bin/qml` with an explicit QML file and
  `QT_QPA_PLATFORM=offscreen` for native checks.
