# qsm-shell

- Build production QML before tests, documents, fixtures, or abstractions.
- A feature is complete only when real QML runs and its visible or interactive
  result has been checked.
- Do not add JavaScript models of QML behavior, expected-red tests, source-shape
  tests, documentation gates, or new manifests.
- Add one focused regression check only after a real behavior works.
- Keep `qsm-desktop` policy, services, persistence, and compositor integration
  out of this library.
- Treat `gallery/` as a design playground. Native QML and the live desktop are
  the runtime truth.
- Design every meaningful resting, hover, pressed, focused, selected, disabled,
  loading, empty, and error state that the component actually supports.
- Pointer and keyboard routes must perform the same action, keep focus visible,
  and provide immediate feedback. Motion communicates state and respects
  `Style.reducedMotion`.
- Review native captures for hierarchy, spacing, contrast, typography, and
  target clarity before calling a visual change complete.
- Use `tokens/deep-night.json` for shared values and regenerate outputs with
  `npm run tokens`.
- Comments explain non-obvious mechanics only. Git history, task history, and
  restatements of code do not belong in source comments.
- Keep durable documentation to `README.md` and `docs/BACKLOG.md` unless a
  genuinely irreversible architectural decision needs a short record.
- Do not claim completion from mocks, lint, screenshots of different surfaces,
  or tests that expect production to fail.
- Run `npm test` before handing work back.
