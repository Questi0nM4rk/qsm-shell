import { readFileSync, writeFileSync } from 'node:fs'
import { spawn } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const args = process.argv.slice(2)
const inspectIndex = args.indexOf('--inspect')
const inspectPath = inspectIndex >= 0 ? args[inspectIndex + 1] : null
const names = args.filter((arg, i) => arg !== '--inspect' && (inspectIndex < 0 || i !== inspectIndex + 1))
const scenarios = JSON.parse(readFileSync(resolve(root, 'previews/scenarios.json'), 'utf8'))

// A scenario key opens that scene; a unit's PascalCase name opens every
// scene that maps to it, side by side in one window, so a TYPE is judged in
// one place.
const keys = names.flatMap((name) =>
  scenarios[name] ? [name] : Object.keys(scenarios).filter((key) => scenarios[key].unit === name),
)

if (names.length === 0 || keys.length === 0) {
  console.error(`usage: npm run preview -- <scenario>... | <Unit>`)
  console.error(`scenarios: ${Object.keys(scenarios).join(', ')}`)
  process.exit(1)
}

const sceneArgs = keys.flatMap((key) => {
  const scenario = scenarios[key]
  const [width, height] = scenario.viewport
  return [scenario.component, scenario.variant, String(width), String(height), scenario.unit ?? '']
})

// No temp file: LivePreview.qml reads the scenes straight from
// Qt.application.arguments after "--", so the same scenario definition drives
// both the capture path and the live window.
const child = spawn(
  '/usr/lib/qt6/bin/qml',
  ['-I', resolve(root, 'qml'), resolve(root, 'previews/LivePreview.qml'), '--', ...sceneArgs],
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
function classify(line) {
  const at = line.indexOf('QSM_INSPECT ')
  if (at >= 0) {
    if (inspectPath)
      writeFileSync(inspectPath, line.slice(at + 'QSM_INSPECT '.length) + '\n')
  } else {
    process.stderr.write(line + '\n')
  }
}

let pending = ''
child.stderr.on('data', (chunk) => {
  pending += chunk
  const lines = pending.split('\n')
  pending = lines.pop()
  for (const line of lines) classify(line)
})
// `close`, not `exit`: `exit` fires as soon as the process is gone, while the
// stderr pipe can still hold unread data -- a crash message written on the way
// out was lost about as often as it was seen. `close` waits for the stream to
// end, so the reader above has already fed every line to `classify`.
child.on('close', (code) => {
  // A child that dies without a trailing newline on stderr leaves one line
  // sitting in `pending` -- classify it too, or it never reaches the
  // terminal or the inspect file.
  if (pending)
    classify(pending)
  process.exit(code || 0)
})
