# Superseded Rollout motion formulas

Historical formula excerpts from `docs/12-mechanism.md`; not the attached-expansion
target. Shared shader composition and hidden-neutral field formulas remain active.

## Physics (squash/stretch spring)

The old travelling body used a symmetric 2x2 deform matrix (rest = 1,0,1), applied
to content and shader about the translated full-body centre:

```text
each frame (dt outside [0.001, 0.1] -> skip the INTEGRATION step only; still resample
prevScenePos so the next frame's velocity is sane):
  vel = (scenePos - prevScenePos) / dt ; speed = |vel|   # logical px/second
  active only when speed > 5.0
  stretch  = 1 + min((speed / 1000) * deformScale, Motion.rolloutDeformLimit)
  compress = 1 / stretch
  c = velX/speed ; s = velY/speed
  target00 = stretch*c*c + compress*s*s
  target01 = (stretch - compress)*c*s
  target11 = stretch*s*s + compress*c*c
  invDamp = 1 / (1 + damping * dt)
  dmVel = (dmVel - stiffness * (dm - target) * dt) * invDamp
  dm   += dmVel * dt
  at rest (|dm - identity| < 0.002 and |dmVel| small and speed < 5): snap to identity
```

Defaults were intensity 0.01, maximum deformation 0.02, stiffness 200 and damping
28. `deformScale` multiplies speed in px/millisecond, not px/second.

## Travelling reveal

```qml
property real offsetScale: shouldBeActive && !suppressed ? 0 : 1
visible: revealAnim.running || offsetScale < 1
readonly property real slideScale: Math.max(0, offsetScale)
implicitWidth: revealHorizontal ? Math.max(0, bodyWidth * (1 - slideScale)) : bodyWidth
implicitHeight: !revealHorizontal ? Math.max(0, bodyHeight * (1 - slideScale)) : bodyHeight
content.x: -bodyWidth * slideScale
Behavior on offsetScale { NumberAnimation { id: revealAnim
    /* Motion.revealLarge / revealSmall and revealCurve / retractCurve */ } }
```

The old shader rect was the full translated body, not the aperture. At left its
local x was `-bodyWidth * slideScale`; at right it was
`viewportWidth - bodyWidth + bodyWidth * slideScale`. Top/bottom used corresponding
y formulas. Radii clamped against full body extents. QML content, shader inverse
and velocity sampling shared the translated body-centre pivot.

Travel ended at the origin wall without overtravel. Effective deformation was
`I + outness * (M - I)` and hidden outness gave identity. The new contract keeps
the neutral shader endpoint but replaces travelling content/paint with a growing
aperture and stationary full-size content.
