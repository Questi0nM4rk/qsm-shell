# TextField

states: rest(surface at 1.2:1 against the background, no border) hover(surfaceHover, 0.4 above rest) press(caret lands) focus(ring, however focus arrived) disabled(surface, text, placeholder, caret and danger border each through Style.disabled) readOnly failed
actions: Accept Clear Reveal(password only) Select all
purposes: text search password number; one type, the purpose switches input semantics, leading glyph, trailing action and sample value together
size: height controlHeight[Sm|Lg]; width naturalWidth = controlWidth, constant, text scrolls inside
tokens: space3 (box inset) space2 (slot gap) spaceTight (caret width, scroll-end inset) radiusMd surface surfaceHover accent danger Style.disabled textSm|Md|Lg
motion: micro (surface, border) press (caret travel); blink = platform cursorFlashTime/2, off under reducedMotion
events: accepted(only when acceptableInput) edited(text) escaped keyPressed(event, the one hook for every key a surface wants, Up/Down included) selectionClaimed
label: outside, through Field, which uses ControlLabel (the element Slider wears)
not designed: multiline, autocomplete, floating label, filled/outlined variants
readOnly: no resting mark (owner ruling; the majority convention across M3, MUI, Fluent, Spectrum, Radix, Ant); it reports at full strength, takes no hover lift and shows no caret, stays a tab stop and copyable
open: audit lines in docs/BACKLOG.md
