# TextField

states: rest hover focus(keyboard ring) disabled readOnly failed
actions: Accept Clear Reveal(password only)
size: height controlHeight[Sm|Lg]; width naturalWidth constant, text scrolls inside
tokens: space3 (box inset) space2 (slot gap) spaceTight (caret width, scroll-end inset) radiusMd surface surfaceHover accent danger opacityDisabled textSm|Md|Lg
motion: micro (surface, border) press (caret travel); blink = platform cursorFlashTime/2, off under reducedMotion
not designed: multiline, autocomplete, floating label, filled/outlined variants
notes: T.TextField root paints scrolled text under leftPadding (first glyph x = -206.3), so the root is T.Control with a clipped TextInput contentItem
conflicts: none
audit: docs/audit-2026-09-09-textfield.md (0 blocker; majors UX-1..3 fixed; UI-1 source-conflict, owner rules)
