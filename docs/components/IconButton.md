# IconButton

A compact, named action for dense shell controls; the caller supplies the glyph and owns the effect.
states: rest, hover, press, focus and disabled; hover and press use the shared StateLayer response, focus rings the complete hit target, disabled blends every painted role through Style.disabled.
actions: pointer click, Space, Enter and the `actions` entry all call `activate()` and emit clicked; callers never synthesize pointer events.
pointer: the whole padded body is the target and reports a pointing cursor; wheel does nothing and propagates.
keyboard: T.Control tab focus and activation; focus remains visible until it leaves.
screen reader: Accessible.Button with accessibleName (defaults to icon for a usable fallback; callers provide a human name where the glyph alone is ambiguous).
size: icon and insets stay caller-settable; the natural target is icon plus the control's paddings and never grows with content.
tokens: iconMd, space3, text, disabled, accent, Motion and StateLayer; no local measurements or colors.
motion: StateLayer's fast press acknowledgement and restrained hover response, removed or reduced by Style.reducedMotion.
not designed: label-bearing primary buttons, loading, toggled state and menus; Capsule, Segmented or a surface-owned row express those concepts.
