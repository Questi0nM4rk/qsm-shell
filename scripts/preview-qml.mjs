import { readFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const [name] = process.argv.slice(2)
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
const result = spawnSync(
  '/usr/lib/qt6/bin/qml',
  ['-I', resolve(root, 'qml'), resolve(root, 'previews/LivePreview.qml'), '--', scenario.component, scenario.variant, String(width), String(height)],
  {
    stdio: 'inherit',
    env: {
      ...process.env,
      QT_FORCE_STDERR_LOGGING: '1',
      QT_OPENGL: 'desktop',
      QT_QPA_PLATFORM: 'wayland',
      QT_QUICK_BACKEND: 'opengl',
      QSG_RHI_BACKEND: 'opengl',
    },
  },
)

process.exit(result.status || 0)
