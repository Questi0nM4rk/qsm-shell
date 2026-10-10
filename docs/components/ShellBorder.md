# ShellBorder

The edge-melt shell frame; it registers rollout regions, bulges and fullscreen capsules and renders the welded seam, and surfaces own every behaviour behind it.
states: none; slots fill up to eight bulges and eight fullscreen capsules with rect, radii, deform and blend parameters each.
actions: register and unregister rollout regions, bulges and fullscreen capsules; snap, weld and seam-overlap geometry helpers; no user-facing route. Fullscreen registrations remain available as input holes; `paint: false` excludes a registration from shader paint while leaving it eligible for the consumer's input mask.
pointer: none; it takes no pointer itself and reads regions only through the host pointer map.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; it is chrome, not content.
size: edge thickness and viewport radius from the frame scale; regions arrive in host coordinates and slots quantize them for the shader.
tokens: frameThickness, radius2xl, meltSmoothing, band and rim strengths and the edge shader; no local colours or measurements.
motion: none; it renders host-animated geometry. Origin sides extend fill through the weld; child-facing rim continuations are paint-only.
registration: snapping skips declared source-origin sides; other nearby edges still snap and cap their welds. Attached expansion supplies a growing aperture with identity deformation. Paint-only normalization does not change content size or viewport input.
paint endpoint: slot outness restores incoming fill/rim distance fields; the emergence stroke gate applies outside the incoming union. Removing a hidden slot must not change frame lighting.
not designed: pointer tracking, rollout behaviour or surface content; use ScenePointer, Rollout or the host for those.
