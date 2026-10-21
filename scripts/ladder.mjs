// The surface ladder, computed once, and the colour maths it stands on. A
// theme types ONE colour, the band; the two steps above it come from here, so
// "each step reads `step`:1 on the one below" is a rule the generator keeps
// rather than a number every theme copies.
//
// Each step keeps the band's hue and chroma and raises OKLCH lightness to the
// first value whose 8-bit sRGB colour, as it ships, reaches the ratio against
// the step below. Contrast is measured on the shipped colour, never the float.
//
// This is the library's public API for theme generators: `ladder` for the two
// steps, and the primitives (`toLch`, `fromLch`, `maxChroma`, `contrast`,
// `luminance`, `parseHex`, `hex`, `stepAbove`) so a generator deriving its
// other colours measures them the same way. Colours are `#rrggbb` strings or
// 0..1 sRGB triples; hue is in radians.

const toLinear = c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4)
const toSrgb = c => (c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055)

export const parseHex = s => [1, 3, 5].map(i => parseInt(s.slice(i, i + 2), 16) / 255)
export const hex = rgb => '#' + rgb.map(c => Math.round(Math.min(1, Math.max(0, c)) * 255).toString(16).padStart(2, '0')).join('')

export function toLch(rgb) {
  const [r, g, b] = rgb.map(toLinear)
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  const a = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s
  const bb = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s
  return { L: 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s, C: Math.hypot(a, bb), h: Math.atan2(bb, a) }
}

export function fromLch({ L, C, h }) {
  const a = C * Math.cos(h)
  const b = C * Math.sin(h)
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
  const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
  const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3
  return [
    toSrgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    toSrgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    toSrgb(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s),
  ]
}

const inGamut = rgb => rgb.every(c => c >= -1e-6 && c <= 1 + 1e-6)

// The largest chroma sRGB still holds at this lightness and hue.
export function maxChroma(L, h) {
  let lo = 0
  let hi = 0.4
  for (let i = 0; i < 40; i++) {
    const mid = (lo + hi) / 2
    if (inGamut(fromLch({ L, C: mid, h }))) lo = mid
    else hi = mid
  }
  return lo
}

export const luminance = rgb => {
  const [r, g, b] = rgb.map(toLinear)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

export const contrast = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x)
  return (hi + 0.05) / (lo + 0.05)
}

// The step above `below` (a hex string): the seed's hue and chroma at the
// smallest lightness that reaches `ratio`, returned as the hex that ships.
export function stepAbove(below, { C, h }, ratio) {
  const against = parseHex(below)
  for (let L = toLch(against).L + 0.001; L < 1; L += 0.001) {
    const shipped = parseHex(hex(fromLch({ L, C: Math.min(C, maxChroma(L, h)), h })))
    if (contrast(shipped, against) >= ratio) return hex(shipped)
  }
  throw new Error(`ladder: no lightness above ${below} reaches ${ratio}:1`)
}

export function ladder(band, step) {
  const seed = toLch(parseHex(band))
  const surface = stepAbove(band, seed, step)
  return { surface, overlay: stepAbove(surface, seed, step) }
}
