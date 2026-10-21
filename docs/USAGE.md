# qsm-shell: usage and development

Reusable QML components and design tokens for Qt 6 and Quickshell desktops.

The product is a fully functional component system with beautiful Quiet
Luminous defaults and responsive, accessible interaction. Callers can compose
different desktops through slots, actions, host-owned state and `Style`; no
single consumer defines the library's policy.
Workbench supports that development and verification. Its chrome is not the
product and is improved only when it blocks component work.

The visual direction is cosy, minimal dusk/night: deep quiet surfaces and
diffuse lilac light, inspired by two dusk wallpapers. A glyph, label,
state and action consequence must tell the same story; generic sample content
is not a design decision.

It knows nothing about any application. Everything an application owns —
services, state, persistence, compositor integration, which keys mean what —
stays with the application; this supplies the vocabulary it draws with.

It provides components, tokens, the edge silhouette shader, and the
`ShellBorder` system that shader exists for: a host that owns the rollout
registries and publishes plain rectangles, leaving Wayland, monitors and input
masks entirely to the consumer.

## Use

Add `qml/` to the QML import path, then install your own token source:

```qml
import qs.QsmShell.Components
import qs.QsmShell.Style

Binding {
    target: Style
    property: "backend"
    value: MyTheme          // any object exposing the token names
}

Capsule {
    icon: "bell"
    label: "Notifications"
    variant: "primary"
}
```

`Style` resolves every value as *your backend first, the library's generated
token as the fallback* — so `Tokens` is the DEFAULT theme, never the theme.

Sizes work the same way. A sized type takes a preset NAME, `size: "md"`, and
resolves it through `Style.size("<Type>", name)` against the theme's size
table (`sizes.<Type>.<name>`, defaults in `tokens/deep-night.json`). Your
backend's `sizes` extends or overrides that table, so `sizes: { Switch: { xl: 40 } }`
makes `Switch { size: "xl" }` valid in your project. A type with no table of
its own (`TextField`, `SpinBox`, `Segmented`, `Capsule`, `IconButton`) belongs
to the `Control` family and shares its ladder, so `sizes: { Control: { xl: 56 } }`
adds `xl` to every one of them. The resolved number (`knobSize`, `thumbSize`,
`fieldHeight`) stays settable directly when one call site needs one value.

A glyph, a line and a body's corner are roles, not call-site choices:
`Style.glyphAlone(box)` and `Style.glyphBeside(box)` pick the icon for a box,
`Style.stroke(n, Screen.devicePixelRatio)` gives a line a whole number of
device pixels, `Style.radiusBody` is the corner of a body directly in a
rollout, and `Style.recede(colour)` dims a colour for "not the current one".
A role derives from the scales and the size table, so a theme changes it by
changing those.

`Interaction` is the one place you state a fact components cannot see for
themselves (whether a hover may claim a selection).

Public types are listed in `qml/QsmShell/Components/qmldir`.

## Links

- Interaction contract (workbench): `../qsm-workbench/docs/interaction-contract.md`
- Workbench provider requirements: `WORKBENCH_PROVIDER.md`
- Owner-review loop: [AGENTS.md](../AGENTS.md)

## What is in it

| | |
| --- | --- |
| **foundation** | `Prose` (ten type roles), `SvgIcon`, `Surface` (a body on the ladder), `Card`, `Divider`, `StateLayer` |
| **controls** | `Capsule`, `IconButton`, `TextField`, `Field`, `ControlLabel`, `Switch`, `Checkbox`, `Radio`, `SpinBox`, `Segmented`, `Slider` (one or two thumbs) |
| **lists** | `ListRow`, `Menu`, `SelectionMark`, `ScrollArea`, `ScrollCue`, `Section`, `Disclosure` |
| **state** | `Spinner`, `ProgressBar`, `Skeleton`, `Callout`, `EmptyState` |
| **readouts** | `Badge`, `Meter`, `Stat`, `StatRing`, `Sparkline`, `KeyValueRow`, `Marquee`, `ColorSwatch`, `Kbd`, `Avatar` |
| **surfaces** | `Popover`, `Dialog`, `Scrim`, `NotificationCard`, `NotificationCenter`, `NotificationStack`, `MonthCalendar`, `ActionTile` |
| **behaviour** | `ArmedAction`, `ScenePointer` |
| **frame** | `ShellBorder`, `Rollout` |
| **shader** | `qml/QsmShell/shaders/edgemelt.frag` plus its committed `.qsb` |

## Develop

```bash
npm run preview                   # the complete provider catalog
npm run preview -- --inspect /tmp/scene.json
npm run capture -- <scenario> /tmp/out.png
npm run unit -- <Type>            # --window runs it on the compositor instead
npm test
bash scripts/build-shaders        # only after editing a .frag; commit .frag + .qsb together
```

- `preview` uses installed `qsm-workbench` on `PATH` with this repo as the
  provider; story names come from `workbench/stories.json`. No sibling checkout
  or source-script fallback is used. A consumer's composed stories belong to
  its own provider, not this component catalog.
- `capture` delegates to the same provider workbench entry point.
- `unit` runs one type's test file under `tests/units/` (falling back to
  `tests/interaction/` for types not yet migrated).
- `test` regenerates tokens, lints QML, and runs the native smoke check plus
  every test directory.
- Provider runtime QML lives under `workbench/`; production components remain
  under `qml/QsmShell/Components/`.

A component is prepared and judged one item at a time. The agent explains its
purpose and reachable states; the owner checks it in the live window and gives
feedback. Revise the same item until accepted before starting the next. Tests,
validation, captures and automated input run only when explicitly requested.
See [AGENTS.md](../AGENTS.md) for the unit contract.

The shader is the one thing here that is not pure QML. Both the `.frag` and the
built `.qsb` are committed, because Quickshell loads the `.qsb` at runtime and
no consumer should need a Qt shader toolchain to run. `npm test` fails if the
committed `.qsb` does not match a rebuild of its `.frag`.

Build real QML with a coherent task fixture and all supported cases reachable.
The owner tests; automated checks are optional, requested evidence. No TDD,
coverage growth or standalone assertions about static styles. Keep docs short,
current and history-free. [AGENTS.md](../AGENTS.md) holds the laws; `develop-component` holds
the owner-review loop.

## Next

The ordered roadmap and per-component
what is true now and what comes next live in [GOAL.md](../GOAL.md#next-in-this-order). Open findings and deferred work
live in [docs/BACKLOG.md](BACKLOG.md).
