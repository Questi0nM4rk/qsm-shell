import { readFileSync, writeFileSync } from 'node:fs'

const tokens = JSON.parse(readFileSync(new URL('../tokens/deep-night.json', import.meta.url)))
// `sizes` is nested two deep (type -> preset name -> number) and stays one
// JSON literal rather than flattening into scalar properties like every
// other group.
const { sizes, ...scalarGroups } = tokens
const entries = Object.entries(scalarGroups).flatMap(([group, values]) => Object.entries(values).map(([name, value]) => [group, name, value]))

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

const scalarLines = entries.map(([group, name, value]) => `    readonly property ${qmlType(group, value)} ${group}${name[0].toUpperCase()}${name.slice(1)}: ${qmlValue(group, value)}`)
const sizesLine = `    readonly property var sizes: (${JSON.stringify(sizes)})`

writeFileSync(new URL('../qml/QsmShell/Style/Tokens.qml', import.meta.url), `pragma Singleton\n\nimport QtQuick\n\nQtObject {\n${[...scalarLines, sizesLine].join('\n')}\n}\n`)
