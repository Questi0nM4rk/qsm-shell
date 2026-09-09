# Controls on Templates: Phase 0 + TextField Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lay the foundation every control rewrite needs (tree dump, `Action` contract, `StateLayer` host mode, ruling, licence, popup spike) and prove it on `TextField`, the first control rebuilt on `QtQuick.Templates` to the definition of done.

**Architecture:** Controls stand on `QtQuick.Templates` (`T.Control` family) and the library paints them through `Style`. `StateLayer` keeps the five states and, when given a template host, reads `hovered`/`pressed`/`visualFocus`/`enabled` from it instead of owning handlers. Every action is a function listed in `actions` as `T.Action` objects so a consumer's action menu can enumerate and trigger them. The preview host dumps its item tree so `ui-audit`/`ux-audit` have real geometry.

**Tech Stack:** Qt 6.11.2 (`/usr/lib/qt6/bin/qml`, `qmltestrunner`, `qmllint`), `QtQuick.Templates`, quickshell 0.3.1 (`qs`) for the popup spike only, node scripts under `scripts/`, bash `scripts/validate-library` as `npm test`.

**Spec:** `docs/adr/0001-controls-on-templates.md`

## Global Constraints

- Every measurement in a component comes from `Style` or `Motion`. No literal numbers in `qml/QsmShell/Components/`. A platform value (`Application.styleHints.cursorFlashTime`) counts as a source, a typed `500` does not.
- Components read `Style`, never `Tokens`.
- `StateLayer` hover is growth or surface lift, never a tint. Focus is a 1px `Style.accent` ring (or the host's semantic colour).
- Every meaningful action is a function on the component; pointer and keyboard routes call it; it is listed in `actions`. The library never sets `Action.shortcut`.
- Public API may break. `qsm-desktop` is out of scope; do not edit it.
- Copy from `$HOME/Clonned/caelestia/repo` where it fits; replace `Tokens.*`/`Colours.*` with `Style.*`, drop M3 roles and C++ plugin types. Licence GPL-3.0.
- Tests: real pointer and key events, behaviour only, never pixels. One focused regression per real behaviour. `tst_units.qml` is the only cross-type test.
- Run `npm test` before every commit. Two pre-existing lint notes are known and not ours to fix here: `previews/Preview.qml:135` unqualified `modelData`, `tests/interaction/tst_surfaces.qml:5` unused import.
- Commit messages via `git commit -F <file>` (backticks in `-m` are eaten by the shell). End each message with:

  ```
  Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EpPqKFkv4uB1qYkM4wajL1
  ```

- Work directly on `master` (owner's call). No branch.
- Live-window checks: announce you are taking the pointer, drive the state trace, then stop and hand over. Move the cursor with damped relative `ydotool mousemove` steps and confirm with `hyprctl cursorpos`. `qml` has no hot reload: restart the window after every edit.

---

## File map

| file | responsibility | task |
| --- | --- | --- |
| `LICENSE` | GPL-3.0 text | 1 |
| `package.json` | `"license": "GPL-3.0-only"` | 1 |
| `tokens/deep-night.json` | `icon.lg` 26 → 24 | 1 |
| `qml/QsmShell/Style/Tokens.qml` | regenerated | 1 |
| `previews/inspect.js` | item-tree walker (ported from the consumer) | 2 |
| `previews/Preview.qml` | `inspect()` + dump on load, control click, F12 | 2 |
| `scripts/preview-qml.mjs`, `scripts/capture-qml.mjs` | `--inspect <file>` flag, filter `QSM_INSPECT` lines from stderr | 2 |
| `tests/units/tst_units.qml` | walk `actions`, trigger each | 3 |
| `qml/QsmShell/Components/StateLayer.qml` | `host` mode | 4 |
| `tests/units/tst_StateLayer.qml` | one host-mode test | 4 |
| `qml/QsmShell/Components/TextField.qml` | rewrite on `T.Control` + `TextInput` | 5 |
| `previews/units/TextField.qml` | actions-driven trailing slot | 5 |
| `tests/units/tst_TextField.qml` | actions route test, API rename | 5 |
| `qml/QsmShell/Components/Field.qml` | uses `TextField` API only if it referenced `setText`/`focusField` (check) | 5 |
| `docs/components/TextField.md` | minimal design record | 6 |
| `AGENTS.md` | name `docs/components/`, name the ADR, note `--inspect` | 6 |
| `docs/BACKLOG.md` | phase status, popup spike result | 6, 7 |
| `previews/spike/popup/shell.qml` | throwaway `T.Popup` in `PanelWindow` | 7 (deleted at the end of 7) |

---

### Task 1: Ruling, licence, token fix

**Files:**

- Create: `LICENSE`
- Modify: `package.json`
- Modify: `tokens/deep-night.json` (`"lg": 26` → `"lg": 24` under `icon`)
- Regenerate: `qml/QsmShell/Style/Tokens.qml` via `npm run tokens`

**Interfaces:**

- Produces: `Style.iconLg === 24`. Consumers: `EmptyState.qml:24`, `Capsule.qml:112`, `ActionTile.qml:57`, `ListRow.qml:83`, `previews/units/Spinner.qml:7`.

- [ ] **Step 1: Add the licence**

```bash
curl -fsSL https://www.gnu.org/licenses/gpl-3.0.txt -o LICENSE
head -3 LICENSE
```

Expected: first line `GNU GENERAL PUBLIC LICENSE`, second `Version 3, 29 June 2007`. If offline, copy `$HOME/Clonned/caelestia/repo/LICENSE` (same text).

- [ ] **Step 2: Declare it in package.json**

Add after `"type": "module",`:

```json
  "license": "GPL-3.0-only",
```

- [ ] **Step 3: Change icon.lg**

In `tokens/deep-night.json` under `"icon"`, change `"lg": 26` to `"lg": 24`. Then:

```bash
npm run tokens && /usr/bin/grep -n "iconLg" qml/QsmShell/Style/Tokens.qml
```

Expected: `readonly property int iconLg: 24`.

- [ ] **Step 4: Run the suite**

```bash
npm test
```

Expected: `qsm-shell validation passed`, 126 tests, 0 failed.

- [ ] **Step 5: Look at the two icon-lg surfaces live**

```bash
npm run preview -- list-row
npm run preview -- action-tile
```

Announce you are taking the pointer. Hover one row and one tile so growth shows, then stop. Record in the final report which of the two the owner should re-judge (glyph at 24 in a 40px row is the case most likely to read small).

- [ ] **Step 6: Commit**

Write `/tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/msg.txt`:

```
chore: GPL-3.0 licence and icon.lg on the 4px rhythm

icon.lg was 26, the one icon size off the 4px scale. 24 is the ruling from
ADR 0001: project tokens win over the blueprint, and the blueprint's 24 is
the one value they disagreed on that the blueprint had right.
```

plus the attribution lines, then:

```bash
git add LICENSE package.json tokens/deep-night.json qml/QsmShell/Style/Tokens.qml
git commit -F /tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/msg.txt
```

---

### Task 2: Item-tree dump in the preview host

**Files:**

- Create: `previews/inspect.js`
- Modify: `previews/Preview.qml` (add `inspect(visibleOnly)`, `dumpTree()`, F12 `Shortcut`, dump after `controlStrip.apply`)
- Modify: `scripts/preview-qml.mjs`, `scripts/capture-qml.mjs` (`--inspect <file>`)

**Interfaces:**

- Produces: `npm run preview -- <key> --inspect /tmp/tree.json` writes the latest tree as JSON: `{ "scene": key, "width", "height", "tree": {type,x,y,w,h,name?,visible?,opacity?,z?,clip?,scale?,color?,radius?,spacing?,growth?,text?,fontPx?,children?} }`. Same fields as the consumer's `qsm inspect`, so `qsm-desktop/scripts/ui-guard` can read either.
- Every dump is one stderr line `QSM_INSPECT <json>`; the node script strips those lines and writes the last one to the file.

- [ ] **Step 1: Write the walker**

`previews/inspect.js`:

```js
.pragma library

// UI forensics walker for the ui-audit / ux-audit skills. Ported from the
// consumer's `qsm inspect` so the same fields come out of both hosts.
// Defaults (visible:true, opacity:1, z:0) are omitted to keep a dump small.

function typeName(item) {
    let name = String(item);
    const paren = name.indexOf("(");
    if (paren !== -1)
        name = name.substring(0, paren);
    // _QMLTYPE_n = named components, _QML_n = anonymous ones.
    const generated = name.search(/_QML(TYPE)?_\d/);
    if (generated !== -1)
        name = name.substring(0, generated);
    if (name.startsWith("QQuick"))
        name = name.substring(6);
    return name;
}

function describe(item, visibleOnly) {
    const origin = item.mapToItem(null, 0, 0);
    const entry = {
        "type": typeName(item),
        "x": Math.round(origin.x * 10) / 10,
        "y": Math.round(origin.y * 10) / 10,
        "w": Math.round(item.width * 10) / 10,
        "h": Math.round(item.height * 10) / 10
    };
    if (item.objectName !== "")
        entry.name = item.objectName;
    if (!item.visible)
        entry.visible = false;
    if (item.opacity < 1)
        entry.opacity = Math.round(item.opacity * 100) / 100;
    if (item.z !== 0)
        entry.z = item.z;
    if (item.clip)
        entry.clip = true;
    if (item.scale !== undefined && item.scale !== 1)
        entry.scale = Math.round(item.scale * 1000) / 1000;
    if (item.color !== undefined)
        entry.color = String(item.color);
    if (item.radius !== undefined)
        entry.radius = item.radius;
    if (item.spacing !== undefined)
        entry.spacing = item.spacing;
    // What a StateLayer GROWS and by how much; the layer's own rect is the
    // hit area, not the thing that moves.
    if (item.hoverScale !== undefined && item.target !== undefined && item.target !== null
        && item.target.mapToItem !== undefined) {
        const grown = item.target.mapToItem(null, 0, 0);
        entry.growth = {
            "x": Math.round(grown.x * 10) / 10,
            "y": Math.round(grown.y * 10) / 10,
            "w": Math.round(item.target.width * 10) / 10,
            "h": Math.round(item.target.height * 10) / 10,
            "scale": item.hoverScale
        };
    }
    if (item.text !== undefined) {
        entry.text = String(item.text);
        if (item.font !== undefined)
            entry.fontPx = item.font.pixelSize;
    }
    const children = [];
    for (let i = 0; i < item.children.length; i++) {
        const child = item.children[i];
        if (visibleOnly && !child.visible)
            continue;
        children.push(describe(child, visibleOnly));
    }
    if (children.length > 0)
        entry.children = children;
    return entry;
}
```

- [ ] **Step 2: Wire it into Preview.qml**

Add after the existing imports:

```qml
import "inspect.js" as Inspect
```

Add inside the root `Rectangle`, after `function unitControls(item) { ... }`:

```qml
    // The audit skills need geometry, not a screenshot. One JSON line on
    // stderr per dump; scripts/preview-qml.mjs turns the last one into a
    // file. Dumped on load, after every control-strip click and on F12.
    function inspect(visibleOnly: bool): var {
        return {
            "scene": `${root.component}/${root.variant}`,
            "width": root.width,
            "height": root.height,
            "tree": Inspect.describe(root, visibleOnly)
        };
    }

    function dumpTree(): void {
        console.info("QSM_INSPECT " + JSON.stringify(root.inspect(true)));
    }

    Shortcut {
        sequence: "F12"
        onActivated: root.dumpTree()
    }

    Timer {
        // One frame after load so layouts have settled; the first dump is
        // the resting state the audit compares everything else against.
        running: root.interactive
        interval: 0
        onTriggered: root.dumpTree()
    }
```

In `controlStrip.apply(...)`, after `controlStrip.applied = next;` add:

```qml
            Qt.callLater(root.dumpTree);
```

- [ ] **Step 3: Teach the two scripts the flag**

In `scripts/preview-qml.mjs` replace `const [name] = process.argv.slice(2)` with:

```js
const args = process.argv.slice(2)
const inspectIndex = args.indexOf('--inspect')
const inspectPath = inspectIndex >= 0 ? args[inspectIndex + 1] : null
const name = args.find((arg, i) => arg !== '--inspect' && i !== inspectIndex + 1)
```

Replace the `spawnSync(...)` block and `process.exit` with:

```js
import { writeFileSync } from 'node:fs'
import { spawn } from 'node:child_process'

const child = spawn(
  '/usr/lib/qt6/bin/qml',
  ['-I', resolve(root, 'qml'), resolve(root, 'previews/LivePreview.qml'), '--', scenario.component, scenario.variant, String(width), String(height), scenario.unit ?? ''],
  {
    stdio: ['inherit', 'inherit', 'pipe'],
    env: {
      ...process.env,
      QT_FORCE_STDERR_LOGGING: '1',
      QT_OPENGL: 'desktop',
      QT_QPA_PLATFORM: 'wayland',
      QSG_RHI_BACKEND: 'opengl',
    },
  },
)

// Dump lines are data for the audit, not noise for the person: they go to
// the --inspect file (last one wins) and never to the terminal.
let pending = ''
child.stderr.on('data', (chunk) => {
  pending += chunk
  const lines = pending.split('\n')
  pending = lines.pop()
  for (const line of lines) {
    const at = line.indexOf('QSM_INSPECT ')
    if (at >= 0) {
      if (inspectPath)
        writeFileSync(inspectPath, line.slice(at + 'QSM_INSPECT '.length) + '\n')
    } else {
      process.stderr.write(line + '\n')
    }
  }
})
child.on('exit', (code) => process.exit(code || 0))
```

(Merge the two `import` lines into the existing import block at the top; keep `readFileSync` and `resolve`.)

In `scripts/capture-qml.mjs`, after `const [name, requestedOutput] = process.argv.slice(2)` the capture path stays synchronous; add the same filter on `result.stderr` before the error check:

```js
const inspectIndex = process.argv.indexOf('--inspect')
const inspectPath = inspectIndex >= 0 ? process.argv[inspectIndex + 1] : null
const dumps = (result.stderr || '').split('\n').filter((l) => l.includes('QSM_INSPECT '))
if (inspectPath && dumps.length > 0)
  writeFileSync(inspectPath, dumps.at(-1).slice(dumps.at(-1).indexOf('QSM_INSPECT ') + 'QSM_INSPECT '.length) + '\n')
```

and make `CapturePreview.qml`'s host `interactive: false` stay as is (the Timer only runs when `interactive`), so add to `Preview.qml`'s Timer: `running: root.interactive || root.captureDump` where `property bool captureDump: false`; set `captureDump: true` in `previews/CapturePreview.qml`'s `Preview { ... }`. Check that file first (`cat previews/CapturePreview.qml`) and add the property on its `Preview` instance.

- [ ] **Step 4: Prove it**

```bash
npm run capture -- text-input --inspect /tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/tree.json
python3 -c "import json;t=json.load(open('/tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/tree.json'));print(t['scene'],t['width'],t['height']);
def walk(n,d=0):
  print(' '*d+n['type'],n.get('name',''),n['x'],n['y'],n['w'],n['h'])
  [walk(c,d+1) for c in n.get('children',[])]
walk(t['tree'])" | head -40
```

Expected: `text-input/text-filled 800 500`, then a tree containing a node named `textFieldInput` and one named `textFieldCaret` with non-zero `w`/`h`.

- [ ] **Step 5: Lint and test**

```bash
npm test
```

Expected: pass. `qmllint` must not complain about `inspect.js` (a `.pragma library` file is fine; if it warns about `Inspect` unqualified access, the fix is the qualified `Inspect.describe` call already used).

- [ ] **Step 6: Commit**

Message:

```
feat(previews): the preview host dumps its item tree for the audit skills

ui-audit's evidence contract needs live geometry, not screenshots, and the
only tree dump lived in the consumer. The host now emits the same JSON
shape on load, after each control click and on F12; `--inspect <file>`
on preview and capture writes the latest dump.
```

---

### Task 3: `actions` walk in tst_units

**Files:**

- Modify: `tests/units/tst_units.qml`

**Interfaces:**

- Consumes: a unit (or the component it is) may declare `readonly property list<T.Action> actions`. Each `T.Action` has `text`, `enabled`, `trigger()`.
- Produces: the one cross-type guarantee: every listed action has a non-empty `text` and can be triggered without throwing.

- [ ] **Step 1: Add the walk**

In `tst_units.qml`, add next to `controlsOf`:

```qml
    // `actions` is the component's own enumeration of what it can do, the
    // list a consumer's action menu renders. Untyped access for the same
    // reason as `controls`: the unit's type is only known at runtime.
    function actionsOf(item) {
        const list = item.actions;
        if (list === undefined || list === null)
            return [];
        const out = [];
        for (let i = 0; i < list.length; i++)
            out.push(list[i]);
        return out;
    }
```

Inside the `for` over `names`, after the `controls` try/catch and before `verify(item !== null, name + ": did not survive its own controls")`, add:

```qml
            const actions = actionsOf(item);
            try {
                for (let a = 0; a < actions.length; a++) {
                    const action = actions[a];
                    verify(typeof action.text === "string" && action.text.length > 0,
                           name + ": action " + a + " has no text, an action menu would show a blank row");
                    verify(typeof action.trigger === "function",
                           name + ": action '" + action.text + "' is not a T.Action");
                    action.trigger();
                }
            } catch (e) {
                fail(name + ": actions: " + e);
            }
```

- [ ] **Step 2: Run it (vacuous today)**

```bash
npm run unit -- units
```

Expected: `Totals: 1 passed`. No unit declares `actions` yet; the walk finds none and passes. Task 5 gives it teeth.

- [ ] **Step 3: Commit**

Message:

```
test(units): walk every unit's declared actions

A consumer's action menu will render `actions`; an entry with no text or
one that throws when triggered is a blank or dead row. The walk is
vacuous until the first component declares the list.
```

---

### Task 4: `StateLayer` host mode

**Files:**

- Modify: `qml/QsmShell/Components/StateLayer.qml`
- Modify: `tests/units/tst_StateLayer.qml`

**Interfaces:**

- Produces: `property var host: null`. When set to a `T.Control` (or any object with `hovered`, `pressed`, `visualFocus`, `enabled`), the layer reads `hovered`, `pressed`, `focused` and `interactive` from it and disables its own `HoverHandler`/`TapHandler`. `clicked` is not emitted in host mode (the host's `clicked`/`accepted` is the event). Everything else (`target`, `response`, focus ring, `hoveredEntered`) unchanged.

- [ ] **Step 1: Write the failing test**

Append to `tst_StateLayer.qml` (add `import QtQuick.Templates as T` to the imports):

```qml
    T.AbstractButton {
        id: hostButton
        x: 20; y: 200; width: 120; height: 32
        hoverEnabled: true
        focusPolicy: Qt.StrongFocus

        StateLayer {
            id: hostedLayer
            anchors.fill: parent
            target: hostButton
            host: hostButton
        }
    }

    function test_host_mode_reads_the_template_states() {
        mouseMove(probe, 340, 220);
        tryCompare(hostedLayer, "hovered", false, 500);

        mouseMove(hostButton, 60, 16);
        tryCompare(hostedLayer, "hovered", true, 500);
        mousePress(hostButton, 60, 16);
        tryCompare(hostedLayer, "pressed", true, 500);
        mouseRelease(hostButton, 60, 16);
        tryCompare(hostedLayer, "pressed", false, 500);

        hostButton.enabled = false;
        compare(hostedLayer.interactive, false, "a disabled host still had an answering layer");
        hostButton.enabled = true;

        // visualFocus is keyboard focus only; a click never sets it.
        hostButton.forceActiveFocus(Qt.TabFocusReason);
        tryCompare(hostedLayer, "focused", true, 500);
    }
```

The test's `height: 240` must grow to `260` so the button is inside the window.

- [ ] **Step 2: Watch it fail**

```bash
npm run unit -- StateLayer
```

Expected: FAIL, `Cannot assign to non-existent property "host"`.

- [ ] **Step 3: Implement host mode**

In `StateLayer.qml` replace the property block from `property bool interactive: true` through `readonly property bool pressed: ...` with:

```qml
    // A template host (T.Control and friends) already owns hovered, pressed,
    // visualFocus and enabled. Given one, the layer READS those and stops
    // running handlers of its own, so a control has one source of every
    // state. `var`, not `Item`: the properties live on the control subclass
    // and a typed Item would make every read a qmllint warning.
    property var host: null
    readonly property bool _hosted: host !== null && host !== undefined

    property bool interactive: _hosted ? host.enabled : true
    property Item target: parent
    property real hoverScale: 1.08
    property real pressScale: 0.94

    // Keyboard focus. In host mode it is `visualFocus`, which Qt sets only on
    // keyboard-reason focus, so a click never paints the ring. Otherwise the
    // host's activeFocus, as before.
    property bool focused: _hosted ? host.visualFocus : (root.parent?.activeFocus ?? false)
    property real focusRadius: 0
    property color focusColor: Style.accent

    readonly property bool hovered: interactive && (_hosted ? host.hovered : hover.hovered)
    readonly property bool pressed: interactive && (_hosted ? (host.pressed ?? false) : tap.pressed)
```

Keep the comment block above `focusRadius` from the current file. Then set the handlers:

```qml
    HoverHandler {
        id: hover
        enabled: !root._hosted
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tap
        enabled: root.interactive && !root._hosted
        onTapped: root.clicked()
    }
```

- [ ] **Step 4: Watch it pass, then the whole file**

```bash
npm run unit -- StateLayer && npm run unit -- StateLayer --window
```

Expected: all StateLayer tests pass under both. If `hovered` never turns true in host mode under offscreen, `hoverEnabled` on the host is the first thing to check (the test sets it explicitly; the component in Task 5 must too).

- [ ] **Step 5: Break it to prove the test has teeth**

Temporarily change `host.hovered` to `false` in the `hovered` binding, run `npm run unit -- StateLayer`, expect `test_host_mode_reads_the_template_states` to FAIL on the hovered line. Revert.

- [ ] **Step 6: Full suite and commit**

```bash
npm test
```

Message:

```
feat(state-layer): read the five states from a template host

A T.Control already owns hovered, pressed, visualFocus and enabled. Given
one as `host`, the layer reads them and switches off its own handlers, so
a control built on QtQuick.Templates has one source of each state instead
of a handler stack racing the template for the same pointer.
```

---

### Task 5: `TextField` on `QtQuick.Templates`

**Files:**

- Modify: `qml/QsmShell/Components/TextField.qml` (rewrite)
- Modify: `previews/units/TextField.qml`
- Modify: `tests/units/tst_TextField.qml`
- Check: `qml/QsmShell/Components/Field.qml`, `tests/interaction/tst_library.qml`, `tests/Smoke.qml` for `setText`/`focusField` calls (`/usr/bin/grep -rn "setText\|focusField" qml tests previews`)

**Interfaces:**

- Produces the public API of `TextField` (root is `T.Control`):
  - properties: `text` (alias), `placeholder`, `size` ("sm"|"md"|"lg"), `inputType` ("text"|"password"|"number"), `failed`, `readOnly`, `passwordVisible`, `validator`, `inputMethodHints`, `naturalWidth`, `leading`/`trailing` (slot aliases), `leadingCursorShape`, `trailingCursorShape`
  - readonly: `acceptableInput`, `focused` (input has active focus), `keyboardFocused` (focus arrived by Tab/Backtab/shortcut; drives the ring)
  - signals: `keyPressed(var event)`, `accepted`, `escaped`, `edited(string text)`, `moveUp`, `moveDown`, `selectionClaimed`
  - functions: `accept(): bool`, `clear(): void`, `toggleReveal(): void`, `selectAll(): void`, `forceActiveFocus()` (inherited; focuses the input via `focusPolicy`)
  - `readonly property list<T.Action> actions`: Accept, Clear, Reveal (Reveal `enabled` only for `inputType === "password"`, `checkable`, `checked: passwordVisible`)
  - removed: `setText(value)` (use `text = value`), `focusField()` (use `forceActiveFocus()`)
- Why `T.Control` and not `T.TextField` as the root: Step 1 measures it.

- [ ] **Step 1: Probe: does `T.TextField` paint glyphs into its padding?**

Write `/tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/probe.qml`:

```qml
import QtQuick
import QtQuick.Templates as T

Item {
    width: 400; height: 120
    T.TextField {
        id: f
        x: 20; y: 40; width: 260; height: 40
        leftPadding: 60; rightPadding: 60
        text: "a very long value that certainly overflows the field twice over"
        color: "white"
        background: Rectangle { color: "#333"; radius: 8 }
        Rectangle { x: 0; y: 0; width: 60; height: parent.height; color: "#800000aa" }
    }
    Component.onCompleted: {
        f.forceActiveFocus(); f.cursorPosition = f.length;
        Qt.callLater(() => { const r = f.positionToRectangle(0); console.info("first glyph x =", r.x, "leftPadding =", f.leftPadding, "contentWidth =", f.contentWidth); Qt.quit(); });
    }
}
```

Run:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_FORCE_STDERR_LOGGING=1 /usr/lib/qt6/bin/qml /tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/probe.qml
```

Read `first glyph x`. If it is **negative or smaller than `leftPadding`**, the text has scrolled left under the padding, which is where a leading slot sits: `T.TextField` cannot host slots without painting text under them, and the rewrite below (root `T.Control`, inner `TextInput` in a clipped `contentItem`, the same shape as Qt's own `T.SpinBox`) is the design. Record the number in `docs/components/TextField.md` under `notes` in Task 6. If it is `>= leftPadding` (Qt clips internally), still proceed with `T.Control` (the rest of the plan depends on it) and note that `T.TextField` root is a later simplification option.

- [ ] **Step 2: Write the failing tests**

In `tests/units/tst_TextField.qml`:

1. Replace every `field.setText(x)` with `field.text = x` and every `composedField.setText(x)` with `composedField.text = x`; replace `field.focusField()` with `field.forceActiveFocus()`.
2. Add `import QtQuick.Templates as T` is NOT needed; add this test at the end:

```qml
    // The action list is the API a consumer's action menu renders. Each
    // entry must be the same route the keyboard takes: Return and the Accept
    // action both go through accept(), Clear empties through clear().
    function test_actions_are_the_same_route_as_the_keys() {
        field.text = "42";
        const names = [];
        for (let i = 0; i < field.actions.length; i++)
            names.push(field.actions[i].text);
        compare(names, ["Accept", "Clear", "Reveal"], "action list changed shape");

        field.actions[0].trigger();
        compare(probe.accepts, 1, "Accept action did not go through accept()");
        keyClick(Qt.Key_Return);
        compare(probe.accepts, 2, "Return and the Accept action are not one route");

        field.actions[1].trigger();
        compare(field.text, "", "Clear action did not clear");

        compare(field.actions[2].enabled, false, "Reveal is enabled on a text field");
        field.inputType = "password";
        compare(field.actions[2].enabled, true, "Reveal is disabled on a password field");
        field.actions[2].trigger();
        compare(field.passwordVisible, true, "Reveal did not toggle passwordVisible");
        field.inputType = "text";
        field.passwordVisible = false;
    }

    function test_focus_ring_follows_keyboard_focus_only() {
        mouseClick(field, 150, 20);
        compare(field.focused, true, "click did not focus the input");
        compare(field.keyboardFocused, false, "a click painted the keyboard focus ring");
        field.focus = false;
        keyClick(Qt.Key_Tab);
        tryCompare(field, "keyboardFocused", true, 500);
    }
```

Also in `init()` replace `field.setText("")` and `field.focusField()` as above.

- [ ] **Step 3: Watch them fail**

```bash
npm run unit -- TextField
```

Expected: compile errors on `field.actions` / `field.visualFocus` / `setText` removed. That is the right failure: the API does not exist yet.

- [ ] **Step 4: Rewrite the component**

Replace `qml/QsmShell/Components/TextField.qml` with (keep the existing header comment about keys, then):

```qml
import QtQuick
import QtQuick.Templates as T

import qs.QsmShell.Style

// THE text input. One line, every state, two slots. Built on T.Control with a
// TextInput contentItem, the shape Qt's own T.SpinBox uses: a T.TextField
// root would paint scrolled glyphs under its own padding (measured, see
// docs/components/TextField.md), and the padding is where the slots live.
//
// ── keys ─────────────────────────────────────────────────────────────────
// (keep the existing keys paragraph from the current file verbatim)
T.Control {
    id: root

    property string placeholder: ""
    property alias text: input.text
    // sm | md | lg
    property string size: "md"
    // text | password | number. A search box is still `text` with a
    // magnifier in its leading slot -- search is not an input type.
    property string inputType: "text"
    // Non-empty paints the failure. The message itself belongs to `Field`.
    property bool failed: false
    property alias readOnly: input.readOnly
    // A password stays a password -- including its input-method hints -- while
    // its host decides whether a trailing reveal action shows the text.
    property bool passwordVisible: false

    // ── slots ───────────────────────────────────────────────────────────
    property alias leading: leadingSlot.data
    property alias trailing: trailingSlot.data
    property int leadingCursorShape: Qt.IBeamCursor
    property int trailingCursorShape: Qt.PointingHandCursor

    // ── the one key hook ────────────────────────────────────────────────
    signal keyPressed(var event)

    signal accepted
    signal escaped
    signal edited(string text)
    signal moveUp
    signal moveDown
    signal selectionClaimed

    readonly property bool acceptableInput: input.acceptableInput
    property var validator: inputType === "number" ? numericValidator : null
    property int inputMethodHints: inputType === "number"
        ? Qt.ImhFormattedNumbersOnly
        : inputType === "password"
            ? Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            : 0

    readonly property bool _sm: size === "sm"
    readonly property bool _lg: size === "lg"
    readonly property bool _password: inputType === "password"
    readonly property int fieldTextSize: _sm ? Style.textSm : _lg ? Style.textLg : Style.textMd
    readonly property bool focused: input.activeFocus

    // ── actions: the one route for pointer, keyboard and menus ──────────
    function accept(): bool {
        if (!root.enabled || !input.acceptableInput)
            return false;
        root.accepted();
        return true;
    }
    function clear(): void { input.clear(); root.edited(input.text); }
    function toggleReveal(): void { root.passwordVisible = !root.passwordVisible; }
    function selectAll(): void { input.selectAll(); }

    // What a consumer's action menu renders for this field. Shortcuts are
    // never set here: which key means what is the surface's call.
    readonly property list<T.Action> actions: [
        T.Action { text: "Accept"; enabled: root.enabled && input.acceptableInput; onTriggered: root.accept() },
        T.Action { text: "Clear"; enabled: root.enabled && !input.readOnly && input.length > 0; onTriggered: root.clear() },
        T.Action {
            text: "Reveal"
            enabled: root.enabled && root._password
            checkable: true
            checked: root.passwordVisible
            onTriggered: root.toggleReveal()
        }
    ]

    DoubleValidator {
        id: numericValidator
        notation: DoubleValidator.StandardNotation
    }

    // A text box's preferred width is a CONSTANT, never its content (the
    // first version stretched across the screen as a person typed).
    property real naturalWidth: Style.notificationWidth
    implicitWidth: Math.max(naturalWidth, leftPadding + rightPadding)
    implicitHeight: _sm ? Style.controlHeightSm : _lg ? Style.controlHeightLg : Style.controlHeight

    // Padding is where the slots sit. The template owns the arithmetic from
    // here: contentItem gets what is left.
    leftPadding: Style.space3 + (leadingSlot.hasContent ? leadingSlot.implicitWidth + Style.space2 : 0)
    rightPadding: Style.space3 + (trailingSlot.hasContent ? trailingSlot.implicitWidth + Style.space2 : 0)

    hoverEnabled: true
    // Focus lands on the input, not the frame: the frame forwards.
    focusPolicy: Qt.NoFocus
    opacity: enabled ? 1 : Style.opacityDisabled

    background: Rectangle {
        radius: Style.radiusMd
        // Hover and press are answered by the SURFACE, not by growth: the
        // caret and the text have to stay where the eye put them.
        color: root.hovered || root.focused ? Style.surfaceHover : Style.surface
        // The one border in the library: a text box's EDGE is the affordance.
        // Invisible at rest, on for focus, danger for failure.
        border.width: root.failed || root.focused ? 1 : 0
        border.color: root.failed ? Style.danger : Style.accent

        Behavior on color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
        Behavior on border.color { ColorAnimation { duration: Motion.micro; easing.type: Motion.standardEasing } }
    }

    // Slots live in the padding, outside the clipped content.
    Item {
        id: leadingSlot
        readonly property bool hasContent: children.length > 0
        x: Style.space3
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    Item {
        id: trailingSlot
        readonly property bool hasContent: children.length > 0
        anchors.right: parent.right
        anchors.rightMargin: Style.space3
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: hasContent ? childrenRect.width : 0
        implicitHeight: hasContent ? childrenRect.height : 0
        width: implicitWidth
        height: implicitHeight
    }

    contentItem: Item {
        // Long text scrolls INSIDE the box; it never stretches it.
        clip: true

        Prose {
            id: placeholder
            anchors.fill: parent
            visible: input.length === 0
            role: "label"
            muted: true
            font.pixelSize: root.fieldTextSize
            verticalAlignment: Text.AlignVCenter
            text: root.placeholder
        }

        TextInput {
            id: input
            objectName: "textFieldInput"
            anchors.fill: parent
            enabled: root.enabled
            activeFocusOnTab: true
            color: Style.text
            selectionColor: Style.accent
            selectedTextColor: Style.background
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontFamily
            font.pixelSize: root.fieldTextSize
            validator: root.validator
            inputMethodHints: root.inputMethodHints
            // Always masked while a password, including the character being
            // typed (echo-on-edit revealed the whole value mid-edit).
            echoMode: root._password && !root.passwordVisible ? TextInput.Password : TextInput.Normal
            // Keeps the scroll-end caret fully inside the clip.
            rightPadding: Style.spaceTight
            // The field draws its own caret below.
            cursorDelegate: Item {}

            onTextEdited: {
                root.selectionClaimed();
                root.edited(text);
            }

            // ONE dispatcher (keep the existing explanatory comment).
            Keys.onPressed: event => {
                root.keyPressed(event);
                if (event.accepted)
                    return;
                switch (event.key) {
                case Qt.Key_Up:
                    root.selectionClaimed(); root.moveUp(); event.accepted = true; break;
                case Qt.Key_Down:
                    root.selectionClaimed(); root.moveDown(); event.accepted = true; break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.selectionClaimed(); root.accept(); event.accepted = true; break;
                case Qt.Key_Escape:
                    root.escaped(); event.accepted = true; break;
                default:
                    break;
                }
            }
        }

        // The caret, drawn by the field (ported from caelestia TextFieldBase):
        // Qt's blinks away during fast typing and is a 1px line at the scroll
        // edge. Moving the caret shows it solid and pauses the blink for one
        // half-cycle; the blink period is the platform's, not a literal.
        Rectangle {
            id: caret
            objectName: "textFieldCaret"
            property bool holdSolid: false
            readonly property int halfPeriod: Application.styleHints.cursorFlashTime / 2
            x: input.x + input.cursorRectangle.x
            y: input.y + input.cursorRectangle.y
            width: Style.spaceTight
            height: input.cursorRectangle.height
            color: Style.accent
            radius: Style.radiusXs
            visible: input.activeFocus && !input.readOnly

            Connections {
                target: input
                function onCursorPositionChanged(): void {
                    caret.opacity = 1;
                    caret.holdSolid = true;
                    holdTimer.restart();
                }
            }
            Timer { id: holdTimer; interval: caret.halfPeriod; onTriggered: caret.holdSolid = false }
            Timer {
                running: caret.visible && !caret.holdSolid && !Style.reducedMotion
                repeat: true
                interval: caret.halfPeriod
                onTriggered: caret.opacity = caret.opacity === 1 ? 0 : 1
            }
            onVisibleChanged: opacity = 1
            Behavior on x { NumberAnimation { duration: Motion.press; easing.type: Motion.standardEasing } }
        }
    }

    // Clicking anywhere in the box puts the caret in it (an empty field's
    // text is a zero-width target). Host mode: hovered/enabled come from the
    // control; nothing scales, so `target: null`.
    StateLayer {
        id: layer
        anchors.fill: parent
        target: null
        host: root
        interactive: root.enabled && !input.readOnly
        focused: root.keyboardFocused
        focusRadius: Style.radiusMd
        focusColor: root.failed ? Style.danger : Style.accent
    }
    // The ring is a KEYBOARD mark. TextInput has no visualFocus; the frame
    // records how focus arrived.
    // Not named `visualFocus`: T.Control already has one (always false here,
    // focusPolicy is NoFocus) and a shadow would be a duplicate property.
    property bool keyboardFocused: false
    Connections {
        target: input
        function onActiveFocusChanged(): void {
            root.keyboardFocused = input.activeFocus
                && (input.focusReason === Qt.TabFocusReason
                    || input.focusReason === Qt.BacktabFocusReason
                    || input.focusReason === Qt.ShortcutFocusReason);
        }
    }

    TapHandler {
        // Tap anywhere on the frame focuses the input; slot actions sit above
        // and take their own taps first.
        onTapped: input.forceActiveFocus(Qt.MouseFocusReason)
    }

    MouseArea {
        id: cursorArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: {
            const leadingPoint = leadingSlot.mapFromItem(cursorArea, mouseX, mouseY);
            const point = trailingSlot.mapFromItem(cursorArea, mouseX, mouseY);
            if (leadingSlot.contains(leadingPoint))
                return root.leadingCursorShape;
            return trailingSlot.contains(point) ? root.trailingCursorShape : Qt.IBeamCursor;
        }
    }
}
```

Notes for the implementer:

- `Item.focusReason` exists on `Item` since Qt 6.7; `input.focusReason` is valid. If qmllint rejects it, read `root.Window.activeFocusItem` instead and drop the reason gate with a note in the record.
- `T.Action` list: if `readonly property list<T.Action>` fails to compile, use `property list<T.Action>` (non-readonly) and keep the objects inline.

- [ ] **Step 5: Update the unit**

In `previews/units/TextField.qml`:

- replace `root.setText("")` with `root.clear()`;
- replace the trailing `IconButton`'s `onClicked` body with: `if (root.passwordExample) root.toggleReveal(); else root.clear();`
- keep everything else. Add a `controls` group is NOT needed: actions are enumerated by `tst_units`.

- [ ] **Step 6: Grep for the removed API**

```bash
/usr/bin/grep -rn "setText\|focusField" qml previews tests
```

Expected: no hits outside the test file you already changed. Fix any that remain (`Field.qml`, `tst_library.qml`, `Smoke.qml`) with `text =` / `forceActiveFocus()`.

- [ ] **Step 7: Run TextField tests offscreen and windowed**

```bash
npm run unit -- TextField && npm run unit -- TextField --window
```

Expected: all pass (11 existing + 2 new). Known differences under `--window`: wheel does not apply here; pointer and keys do.

- [ ] **Step 8: Teeth**

Temporarily make `accept()` skip `root.accepted()`; run `npm run unit -- TextField`; expect `test_actions_are_the_same_route_as_the_keys` and `test_unclaimed_keys_fall_through_to_the_field` to fail naming accept. Revert.

- [ ] **Step 9: Full suite**

```bash
npm test
```

Expected: pass. `tst_units` now walks 3 actions on the TextField unit.

- [ ] **Step 10: Live window**

```bash
npm run preview -- text-input --inspect /tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/tree.json
```

Announce you are taking the pointer. Trace: hover (surface lifts, no growth), click into the field (caret solid, no ring), type a value longer than the box (text scrolls, box width constant, caret one `space2` from the trailing action), Tab away and Shift+Tab back (ring appears), click `purpose/password` in the strip (dots, Reveal in the trailing slot), press F12 and read `tree.json`: `textFieldInput` `w` equals field width minus paddings, `textFieldCaret` `x` inside the content item. Then stop and hand over.

- [ ] **Step 11: Commit**

Message:

```
feat(text-field): TextField stands on QtQuick.Templates

T.Control owns padding, hovered and the enabled cascade; a TextInput
contentItem owns the text, because a T.TextField root paints scrolled
glyphs under its own padding, which is where the slots live (measured).
StateLayer runs in host mode. accept(), clear() and toggleReveal() are the
one route for Return, the trailing action and the new `actions` list; the
caret is the field's own, with the platform blink period.

setText() and focusField() are gone: `text =` and forceActiveFocus().
```

---

### Task 6: Records and docs

**Files:**

- Create: `docs/components/TextField.md`
- Modify: `AGENTS.md`, `docs/BACKLOG.md`

- [ ] **Step 1: The record**

`docs/components/TextField.md`:

```markdown
# TextField

states: rest hover focus(keyboard ring) disabled readOnly failed
actions: Accept Clear Reveal(password only)
size: height controlHeight[Sm|Lg]; width naturalWidth constant, text scrolls inside
tokens: space3 (box inset) space2 (slot gap) spaceTight (caret width, scroll-end inset) radiusMd surface surfaceHover accent danger opacityDisabled textSm|Md|Lg
motion: micro (surface, border) press (caret travel); blink = platform cursorFlashTime/2, off under reducedMotion
not designed: multiline, autocomplete, floating label, filled/outlined variants
notes: T.TextField root paints scrolled text under leftPadding (first glyph x = <value from Task 5 step 1>), so the root is T.Control with a clipped TextInput contentItem
conflicts: none
```

Fill the `<value>` from the probe.

- [ ] **Step 2: AGENTS.md**

Under "Keep durable documentation to `README.md` and `docs/BACKLOG.md` unless..." append: `docs/adr/` holds the irreversible decisions (ADR 0001: controls on QtQuick.Templates) and `docs/components/<Type>.md` holds one short design record per type, the `expected` column an audit measures against.` In the Preview workflow section, after the `Commands:` bullet, add: `--inspect <file>` on `preview` and `capture` writes the latest item-tree dump (same shape as the consumer's `qsm inspect`); F12 re-dumps in the live window.` In Component laws, add one law:

```
- **A text root paints under its own padding.** `T.TextField` scrolls long
  text left under `leftPadding`, which is where a leading slot sits. A text
  control with slots is a `T.Control` with a clipped `TextInput` content
  item, the shape `T.SpinBox` uses; the template still owns padding and
  states.
```

(Only if Task 5 Step 1 measured the bleed. Otherwise write the law as the measured negative.)

- [ ] **Step 3: BACKLOG**

Replace the first paragraph under `### Preview/test migration underway` with a two-paragraph status: ADR 0001 accepted 2026-09-09; phase 0 items done (tree dump, actions walk, StateLayer host mode, icon.lg ruling, licence); `TextField` is the first type at the definition of done; next types in order: `Slider` (+`RangeSlider`), `Switch`, `Checkbox`+`Radio`, buttons on `T.AbstractButton`, `SpinBox`, `Segmented` on `T.TabBar`, `ScrollArea` on `T.ScrollBar`, popup family per Task 7's result. Keep the OPEN items below it.

- [ ] **Step 4: Commit**

```bash
npm test
```

Message: `docs: TextField design record, ADR and inspect flag in AGENTS.md`.

---

### Task 7: Popup spike under quickshell

**Files:**

- Create then delete: `previews/spike/popup/shell.qml`
- Modify: `docs/BACKLOG.md` (result)

**Interfaces:**

- Produces: a go/no-go line in BACKLOG for `Menu`/`Popover`/`Dialog`/`ToolTip` on `T.Popup`.

- [ ] **Step 1: Write the spike**

```qml
import QtQuick
import QtQuick.Templates as T
import Quickshell
import Quickshell.Wayland

ShellRoot {
    PanelWindow {
        id: panel
        anchors { top: true; left: true; right: true }
        implicitHeight: 48
        color: "#1c0e27"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: anchorButton
            x: 200; y: 8; width: 120; height: 32; radius: 8; color: "#443355"
            Text { anchors.centerIn: parent; text: "open"; color: "white" }
            TapHandler { onTapped: popup.opened ? popup.close() : popup.open() }
        }

        T.Popup {
            id: popup
            parent: anchorButton
            x: 0; y: anchorButton.height + 4
            width: 240; height: 160
            closePolicy: T.Popup.NoAutoClose
            background: Rectangle { color: "#2a1a3a"; radius: 12; border.color: "#c5a5e9" }
            contentItem: Text { text: "T.Popup inside PanelWindow\nclosePolicy NoAutoClose"; color: "white"; padding: 12 }
            onOpenedChanged: console.info("popup opened =", opened, "at", popup.x, popup.y, "parent height", panel.height)
        }
    }
}
```

- [ ] **Step 2: Run it**

```bash
qs -p previews/spike/popup &
sleep 2; hyprctl clients -j | python3 -c "import json,sys;[print(c['class'],c['title'],c['at'],c['size']) for c in json.load(sys.stdin) if 'quickshell' in c['class'].lower()]"
```

Announce you are taking the pointer. Move to the `open` button (damped relative `ydotool mousemove`, confirm with `hyprctl cursorpos`), click, and `grim` a screenshot via `bun "$QSM_MARKETPLACE/tools/qsm-uix/scripts/ui-capture.ts" shot --out /tmp/claude-1000/-home-qs-m4rk-Projects-qsm-shell/a9ddd88b-f917-4f92-a710-b5bd6109c291/scratchpad/popup.png`. Questions to answer from the image and the console line:

1. Does the popup paint at all? (A 48px-tall layer-shell window cannot show a 160px popup below it: the popup lives in the panel's window. Expect it clipped or invisible; that is the finding.)
2. Does it stay open with `NoAutoClose` when the pointer leaves?
3. Does moving `popup.y` to a negative value (above the button) paint inside the 48px?

Then `kill %1`.

- [ ] **Step 3: Record**

In `docs/BACKLOG.md` under the OPEN items add one entry: `Popup spike 2026-09-09: T.Popup in a PanelWindow <paints / does not paint> outside the window's own rect; NoAutoClose <held / did not hold>. Decision: <Menu/Popover/Dialog/ToolTip stay hand-rolled over Rollout/Popover | can move to T.Popup for in-window placement only>.` Fill the brackets with what you measured.

- [ ] **Step 4: Delete the spike and commit**

```bash
rm -r previews/spike && npm test
```

Message: `docs: popup spike result, T.Popup under a PanelWindow`.

---

### Task 8: Audit pass on TextField

**Files:**

- Modify (only if findings): `qml/QsmShell/Components/TextField.qml`, `docs/components/TextField.md`

- [ ] **Step 1: Run the two audits as a subagent**

Dispatch one subagent with these instructions: read `$HOME/Projects/FullStack.qsm/qsm-marketplace/adapters/claude/modules/qsm-uix/skills/ui-audit/SKILL.md` and `.../ux-audit/SKILL.md` and their `references/`, then audit the live `text-input` scenario. Evidence channels: `npm run preview -- text-input --inspect <file>` for the tree (F12 after each state), `bun "$QSM_MARKETPLACE/tools/qsm-uix/scripts/ui-capture.ts" shot|crop|contrast|scan` for captures, `docs/components/TextField.md` + `tokens/deep-night.json` as the design source. States to enumerate: rest, hover, focus by click, focus by Tab, filled, long value, password, number, failed, readOnly, disabled. Return the findings table and the **Not examined** list, nothing else.

- [ ] **Step 2: Fix blockers and majors in the component; record minors**

Each fix: one focused regression test only if it is a behaviour (a geometry fix has the tree dump as its check, not a test). Re-run `npm test`.

- [ ] **Step 3: Owner judgement**

Open `npm run preview -- text-input`, drive the same trace as Task 5 Step 10, stop, and hand over. The task is done when the owner says so, not before.

- [ ] **Step 4: Commit**

Message: `fix(text-field): <what the audit found>` or, if nothing, no commit.
