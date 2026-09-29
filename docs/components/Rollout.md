# Rollout

An edge reveal container that reports hover intent and stays open while the pointer is inside its hitbox plus a grace delay; it never closes itself.
states: revealed and hidden with overshoot on the way out; `suppressed` snaps shut; `hovered` is the pointer inside now and `keepOpen` adds the delay; `wantsOpen` combines trigger, hover and keep-open for the surface.
actions: none of its own; `triggered`, `hovered`, `keepOpen` and `wantsOpen` report upward and the surface owns `shouldBeActive`.
pointer: presence reads through the host pointer map over registered areas; the component paints nothing and claims no events itself.
keyboard: none; it takes no keys and holds no focus.
screen reader: no role of its own; revealed content names itself.
size: the body viewport plus padding on every side; extrusion follows the reveal axis; fullscreen mode takes the capsule geometry instead.
tokens: frameThickness, rolloutRadius, meltSmoothing, space4 and radiusPill; no local colours or measurements.
motion: reveal and retract curves on offset with a settle scale on content; the goo deform pauses under reduced motion; close delay is the hover grace.
not designed: placement, dismissal policy or the revealed content; use Popover, Dialog or the host for those.
