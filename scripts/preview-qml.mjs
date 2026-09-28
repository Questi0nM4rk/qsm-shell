import { spawn } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const workbench = resolve(root, '../qsm-workbench/scripts/workbench.mjs')
const child = spawn(process.execPath, [workbench, '--provider', root, ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: process.env,
})

child.on('error', (error) => {
  console.error(`could not start qsm-workbench: ${error.message}`)
  process.exit(1)
})
child.on('close', (code) => { process.exitCode = code ?? 1 })
