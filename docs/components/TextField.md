# TextField

states: rest hover press(caret lands, no other answer) focus(keyboard ring) disabled(surface, text, placeholder, caret and danger border each through Style.disabled -- colour, never opacity on the frame, which would let whatever sits behind the field read through its own value) readOnly failed
actions: Accept Clear Reveal(password only) Select all
size: height controlHeight[Sm|Lg]; width naturalWidth constant, text scrolls inside
tokens: space3 (box inset) space2 (slot gap) spaceTight (caret width, scroll-end inset) radiusMd surface surfaceHover accent danger Style.disabled(opacityDisabled) textSm|Md|Lg
motion: micro (surface, border) press (caret travel); blink = platform cursorFlashTime/2, off under reducedMotion
not designed: multiline, autocomplete, floating label, filled/outlined variants
notes: T.TextField root paints scrolled text under leftPadding (first glyph x = -206.3), so the root is T.Control with a clipped TextInput contentItem
conflicts: UI-1 resting boundary (3:1 rubric vs no-box-at-rest law); UX-6 readOnly resting mark; both OPEN, owner rules
known: UX-7 click then Tab-wrap onto the same item keeps the pointer mark (no ring); UX-8 disable/re-enable auto-restores focus and rings without a Tab (audit)
audit: docs/audit-2026-09-09-textfield.md (0 blocker; majors UX-1..3 fixed; UI-1 source-conflict, owner rules)
released: 2026-09-09
