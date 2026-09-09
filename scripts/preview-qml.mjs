import { readFileSync, writeFileSync } from 'node:fs'
import { spawn } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const args = process.argv.slice(2)
const inspectIndex = args.indexOf('--inspect')
const inspectPath = inspectIndex >= 0 ? args[inspectIndex + 1] : null
const name = args.find((arg, i) => arg !== '--inspect' && (inspectIndex < 0 || i !== inspectIndex + 1))
const scenarios = JSON.parse(readFileSync(resolve(root, 'previews/scenarios.json'), 'utf8'))
const scenario = scenarios[name]

if (!scenario) {
  console.error(`usage: npm run preview -- <component>`)
  console.error(`components: ${Object.keys(scenarios).join(', ')}`)
  process.exit(1)
}

const [width, height] = scenario.viewport

// No temp file: LivePreview.qml reads component/variant/width/height straight
// from Qt.application.arguments after "--", so the same scenario definition
// drives both the capture path and the live window.
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
