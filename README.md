<div align="center">

# `qsm-shell`

**Qt 6 components and design tokens for a Quickshell desktop on Hyprland, built for my own setup.**

[![last commit](https://img.shields.io/github/last-commit/Questi0nM4rk/qsm-shell)](https://github.com/Questi0nM4rk/qsm-shell/commits)
[![license](https://img.shields.io/badge/license-GPL--3.0-blue)](./LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-0.3-8a7fd6)](https://quickshell.org)
[![QML](https://img.shields.io/badge/QML-Qt%206-41cd52)](https://doc.qt.io/qt-6/qmlapplications.html)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff)](https://hypr.land)

</div>

```qml
import qs.QsmShell.Components

Capsule {
    icon: "bell"
    label: "Notifications"
    variant: "primary"
}
```

## Why it exists

I like building my own stuff and owning the tools I use, and that includes the desktop I look at all day.
Ready-made shell configs mix their look, their state and their services into one block, so changing one thing means reading all of it.
This library keeps only the vocabulary a shell draws with: components, tokens and one edge shader.
It refuses to own services, state or compositor wiring; the application that uses it does.
It would have no reason to exist if I stopped writing my own shell.

## Quickstart

Requires Arch Linux, Hyprland, Quickshell 0.3 and Qt 6.12 (`qt6-declarative`, `qt6-shadertools`).

```bash
git clone https://github.com/Questi0nM4rk/qsm-shell && cd qsm-shell
bash scripts/validate-library
```

`validate-library` regenerates the tokens, runs `qmllint` on all QML, a headless smoke test and the
`qmltestrunner` suites (offscreen, no compositor), and checks that the committed shader build matches its source.

To use the components, add `qml/` to the QML import path of your own Quickshell config
and `import qs.QsmShell.Components`. Details are in [docs/USAGE.md](docs/USAGE.md).

## How it works

```text
qml/QsmShell/Components/   public types (Capsule, Menu, Slider, Rollout, ...), listed in qmldir
qml/QsmShell/Style/        Style singleton: your theme first, generated tokens as the fallback
qml/QsmShell/shaders/      edgemelt.frag and its committed .qsb
tokens/deep-night.json     default theme, compiled to QML by scripts/generate-tokens.mjs
tests/                     smoke, interaction and per-type unit tests
workbench/                 story catalog that a separate preview tool reads
docs/                      usage, component notes, decisions, backlog
```

`Style` reads each value from your theme object first and from the generated default second.
Sizes are preset names such as `size: "md"`, which your theme can extend.
The application owns state and passes it in through slots and actions.

## Numbers

[![last commit](https://img.shields.io/github/last-commit/Questi0nM4rk/qsm-shell)](https://github.com/Questi0nM4rk/qsm-shell/commits)

| What | How to measure |
| --- | --- |
| QML files | `scc --no-cocomo qml tests workbench scripts`, QML row, Files column |
| QML code lines | `scc --no-cocomo qml tests workbench scripts`, QML row, Code column |
| All code lines (QML, JSON, SVG, GLSL, shell, JS) | `scc --no-cocomo qml tests workbench scripts`, Total row, Code column |
| Icons (SVG) | `ls qml/QsmShell/assets/icons/*.svg \| wc -l` |

Commits include agent-authored work under my identity; design, orchestration and review are mine.

## Status

- Works: the component set in `qml/QsmShell/Components`, the token system, the edge shader, and most of
  the interaction tests. The script stops at the first failure, so the suites after it do not run.
- Known failure: `scripts/validate-library` exits 1 because
  `test_notification_center_remove_selected_reports_without_mutating_entries` fails.
- Known gaps: `qmllint` prints warnings (for example `id-shadows-member` in `Capsule.qml`), so it is
  not warning-free. Open items are in [docs/BACKLOG.md](docs/BACKLOG.md).
- Experimental: `npm run preview` and `npm run capture` need `qsm-workbench`, which is not published yet.
- Consumers use the public API only (`Style`, `Motion`, the components and `Style.backend`); the library knows nothing about any one of them.
- Written for one person and one setup. No stability promise for the API.

## License

[GPL-3.0](./LICENSE). The library runs on [Quickshell](https://quickshell.org).
