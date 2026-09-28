import { existsSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const args = process.argv.slice(2)
const windowed = args.includes('--window')
const name = args.find((arg) => arg !== '--window')

// QML_XHR_ALLOW_FILE_READ lets provider runtime tests read workbench files
// over XHR. Qt disables local-file GET by default. It belongs here rather
// than in package.json so the runner works however it is invoked.
const env = windowed
  ? { QT_QPA_PLATFORM: 'wayland', QT_OPENGL: 'desktop', QML_XHR_ALLOW_FILE_READ: '1' }
  : { QT_QPA_PLATFORM: 'offscreen', QT_QUICK_BACKEND: 'software', QML_XHR_ALLOW_FILE_READ: '1' }

function runInput(inputPath) {
  const result = spawnSync('/usr/lib/qt6/bin/qmltestrunner', ['-import', resolve(root, 'qml'), '-input', inputPath], {
    stdio: 'inherit',
    env: { ...process.env, ...env },
  })
  return result.status ?? 1
}

if (name) {
  // tests/units/ does not exist yet -- the lookup falls through to
  // tests/interaction/ rather than treating the miss as an error.
  const candidates = [resolve(root, `tests/units/tst_${name}.qml`), resolve(root, `tests/interaction/tst_${name}.qml`)]
  const file = candidates.find(existsSync)
  if (!file) {
    console.error(`unit: no tst_${name}.qml under tests/units/ or tests/interaction/`)
    process.exit(1)
  }
  process.exit(runInput(file))
}

// No name: run every directory of test files that exists, the way
// validate-library does today. qmltestrunner takes one -input at a time, so
// each existing directory gets its own run and the worst exit code wins.
const dirs = ['tests/units', 'tests/interaction'].map((d) => resolve(root, d)).filter(existsSync)
let exitCode = 0
for (const dir of dirs) {
  const code = runInput(dir)
  if (code !== 0)
    exitCode = code
}
process.exit(exitCode)
