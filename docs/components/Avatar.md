# Avatar

A masked person picture with a fallback glyph or initials, an optional presence dot and an optional progress ring; it reports identity and never takes input.
states: photo when the image is ready, icon fallback, initials fallback; a status dot shows only when `status` names a tone, a ring only while `progress` is set.
actions: none; no signals, no functions and no pointer, keyboard or programmatic route.
pointer: none; it never claims hover, press, focus or wheel.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: a graphic named by `name` and described by `statusLabel` ("Online"), because the dot's hue reaches nobody who cannot see it; a nameless one (album art) is ignored, the host's own label speaks for it.
size: one `size` box for the picture; the implicit size grows by the ring room (gap plus ring width, whole pixels, even) only while ringed; `radius` defaults to `Style.radiusPill`, a circle, and a sleeve states `Style.radiusBody`; `glyphSize` defaults to two fifths of it and the initials and the glyph snap to the type and icon scales; the presence dot is a fifth of `size` on the 4px rhythm, centred on the rim at 45 degrees and cut out of the picture by a half step of `ground` (the colour the avatar sits on, `Style.band` by default).
reference: Chakra UI's AvatarBadge sits on the avatar's corner with a border in the page colour (https://v2.chakra-ui.com/docs/components/avatar); the cut-out follows it.
rim: the mask ramps its edge pixel (`maskThresholdMin` 0.5, `maskSpreadAtMin` 1), so a round photograph has a smooth rim; a host places the avatar on whole device pixels.
properties: `source`, `name`, `icon`, `size`, `background`, `status`, `statusLabel`, `ground`, `progress`, `progressColor`, `progressTrack`, `ringWidth`, `ringGap`, `glyphSize`, `radius`.
tokens: the Control size table, overlay, band, text, textMuted, spaceTight, rhythm, textNear, iconNear, Prose, SvgIcon, StatRing and Badge; no local colours; the dot and ring proportions are ratios of `size`.
motion: none of its own; the dot's colour animates in Badge (`Motion.micro`); image and ring settle without animation.
measured (rendered, scale 1.25): initials and glyph 5.04:1 on the overlay ground; the dot 8.8:1 against the band; the photograph's rim is anti-aliased where a hard stair-step was; no stray warning from the dot, which carries its `statusLabel`.
not designed: selection, action, editing, a badge count or a menu; use Badge, IconButton or the host for those.
