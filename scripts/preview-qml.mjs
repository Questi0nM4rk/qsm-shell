import { spawn } from 'node:child_process'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const child = spawn('qsm-workbench', ['--provider', root, ...process.argv.slice(2)], {
  stdio: 'inherit',
  env: process.env,
})

child.on('error', (error) => {
  console.error(`could not start installed qsm-workbench (required on PATH): ${error.message}`)
  process.exit(1)
})
child.on('close', (code) => { process.exitCode = code ?? 1 })
