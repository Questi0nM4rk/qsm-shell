import { readFileSync, writeFileSync } from 'node:fs'
import { spawn } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const args = process.argv.slice(2)
const inspectIndex = args.indexOf('--inspect')
const inspectPath = inspectIndex >= 0 ? args[inspectIndex + 1] : null
const names = args.filter((arg, i) => arg !== '--inspect' && (inspectIndex < 0 || i !== inspectIndex + 1))
const scenarios = JSON.parse(readFileSync(resolve(root, 'previews/scenarios.json'), 'utf8'))

// A unit switches scenes inside its own window rather than opening one
// window per scene, so the group a key belongs to is what a name resolves
// to: `unit` for a migrated key, `component` for a legacy one still keyed
// only by itself.
const groupOf = (key) => scenarios[key].unit || scenarios[key].component

// scenarios.json order, grouped -- the group's first key is its default
// scene.
const keysByGroup = new Map()
for (const key of Object.keys(scenarios)) {
  const group = groupOf(key)
  if (!keysByGroup.has(group))
    keysByGroup.set(group, [])
  keysByGroup.get(group).push(key)
}

// One request per distinct group: a literal scenario key opens that key as
// the initial scene, a unit/group name opens the group's default (first)
// key. The first name to reach a group wins its initial scene.
const requests = new Map()
for (const name of names) {
  if (scenarios[name]) {
    const group = groupOf(name)
    if (!requests.has(group))
      requests.set(group, name)
  } else if (keysByGroup.has(name)) {
    if (!requests.has(name))
      requests.set(name, keysByGroup.get(name)[0])
  }
}

if (names.length === 0 || requests.size === 0) {
  console.error(`usage: npm run preview -- <scenario>... | <Unit>...`)
  console.error(`scenarios: ${Object.keys(scenarios).join(', ')}`)
  process.exit(1)
}

// No temp file: LivePreview.qml reads its scene straight from
// Qt.application.arguments after "--", so the same scenario definition
// drives both the capture path and the live window.
for (const [group, initialKey] of requests) {
  const scenes = keysByGroup.get(group).map((key) => ({
    key,
    component: scenarios[key].component,
    variant: scenarios[key].variant,
    viewport: scenarios[key].viewport,
    unit: scenarios[key].unit ?? '',
  }))

  const child = spawn(
    '/usr/lib/qt6/bin/qml',
    ['-I', resolve(root, 'qml'), resolve(root, 'previews/LivePreview.qml'), '--', initialKey, JSON.stringify(scenes)],
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
  // the --inspect file (last one wins across every window) and never to the
  // terminal.
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
  // `close`, not `exit`: `exit` fires as soon as the process is gone, while
  // the stderr pipe can still hold unread data -- a crash message written on
  // the way out was lost about as often as it was seen. `close` waits for
  // the stream to end, so the reader above has already fed every line to
  // `classify`.
  child.on('close', (code) => {
    // A child that dies without a trailing newline on stderr leaves one line
    // sitting in `pending` -- classify it too, or it never reaches the
    // terminal or the inspect file.
    if (pending)
      classify(pending)
    if (code)
      process.exitCode = code
  })
}
