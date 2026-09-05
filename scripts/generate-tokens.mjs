import { readFileSync, writeFileSync } from 'node:fs'

const tokens = JSON.parse(readFileSync(new URL('../tokens/deep-night.json', import.meta.url)))
const entries = Object.entries(tokens).flatMap(([group, values]) => Object.entries(values).map(([name, value]) => [group, name, value]))

// QML typing: colors are hex strings under the `color` group; other strings are
// real `string` properties (e.g. font families); integers are `int`; fractional
// numbers (opacity) are `real`.
const qmlType = (group, value) =>
  group === 'color' ? 'color'
  : typeof value === 'string' ? 'string'
  : Number.isInteger(value) ? 'int'
  : 'real'

const qmlValue = (group, value) =>
  group === 'color' || typeof value === 'string' ? `"${value}"` : `${value}`

writeFileSync(new URL('../qml/QsmShell/Style/Tokens.qml', import.meta.url), `pragma Singleton\n\nimport QtQuick\n\nQtObject {\n${entries.map(([group, name, value]) => `    readonly property ${qmlType(group, value)} ${group}${name[0].toUpperCase()}${name.slice(1)}: ${qmlValue(group, value)}`).join('\n')}\n}\n`)
