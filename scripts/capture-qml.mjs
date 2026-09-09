import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { dirname, resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const rawArgs = process.argv.slice(2)
const inspectIndex = rawArgs.indexOf('--inspect')
const inspectPath = inspectIndex >= 0 ? rawArgs[inspectIndex + 1] : null
// --inspect and its value are flags, not the positional <component>
// [output.png] pair -- strip them before reading positional args.
const positional = rawArgs.filter((arg, i) => arg !== '--inspect' && (inspectIndex < 0 || i !== inspectIndex + 1))
const [name, requestedOutput] = positional
const scenarios = JSON.parse(readFileSync(resolve(root, 'previews/scenarios.json'), 'utf8'))
const scenario = scenarios[name]

if (!scenario) {
  console.error(`usage: npm run capture -- <component> [output.png]`)
  console.error(`components: ${Object.keys(scenarios).join(', ')}`)
  process.exit(1)
}

const output = resolve(requestedOutput || `/tmp/qsm-shell-${name}.png`)
const template = readFileSync(resolve(root, 'previews/CapturePreview.qml'), 'utf8')
const [width, height] = scenario.viewport
const qml = template
  .replace('property string targetComponent: "capsule"', `property string targetComponent: "${scenario.component}"`)
  .replace('property string targetUnit: ""', `property string targetUnit: "${scenario.unit ?? ''}"`)
  .replace('property string targetVariant: "resting"', `property string targetVariant: "${scenario.variant}"`)
  .replace('property int targetWidth: 1600', `property int targetWidth: ${width}`)
  .replace('property int targetHeight: 900', `property int targetHeight: ${height}`)
  .replace('property string outputPath: "/tmp/qsm-capture.png"', `property string outputPath: "${output.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"`)

const temporary = resolve(root, 'previews', `.capture-${process.pid}.qml`)
mkdirSync(dirname(output), { recursive: true })
rmSync(output, { force: true })
writeFileSync(temporary, qml)

const result = spawnSync('/usr/lib/qt6/bin/qml', ['-I', resolve(root, 'qml'), temporary], {
  encoding: 'utf8',
  env: {
    ...process.env,
    QT_FORCE_STDERR_LOGGING: '1',
    QT_OPENGL: 'desktop',
    QT_QPA_PLATFORM: 'offscreen',
    QSG_RHI_BACKEND: 'opengl',
  },
})

rmSync(temporary, { force: true })

const dumps = (result.stderr || '').split('\n').filter((l) => l.includes('QSM_INSPECT '))
if (inspectPath && dumps.length > 0)
  writeFileSync(inspectPath, `${dumps.at(-1).slice(dumps.at(-1).indexOf('QSM_INSPECT ') + 'QSM_INSPECT '.length)}\n`)

if (result.status !== 0 || !existsSync(output)) {
  console.error(result.stderr || result.stdout || 'QML capture failed')
  process.exit(result.status || 1)
}

console.log(output)
