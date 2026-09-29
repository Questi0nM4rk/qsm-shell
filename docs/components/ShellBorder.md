# ShellBorder

The edge-melt shell frame; it registers rollout regions, bulges and fullscreen capsules and renders the welded seam, and surfaces own every behaviour behind it.
states: none; slots fill up to eight bulges and eight fullscreen capsules with rect, radii, deform and blend parameters each.
actions: register and unregister calls for rollout regions, bulges and fullscreen capsules plus snap, weld and seam-overlap geometry helpers; no signals and no user-facing route.
pointer: none; it takes no pointer itself and reads regions only through the host pointer map.
keyboard: none; it is never a tab stop and takes no keys.
screen reader: none; it is chrome, not content.
size: edge thickness and viewport radius from the frame scale; regions arrive in host coordinates and slots quantize them for the shader.
tokens: frameThickness, radius2xl, meltSmoothing, band and rim strengths and the edge shader; no local colours or measurements.
motion: none; it renders the geometry hosts animate elsewhere.
not designed: pointer tracking, rollout behaviour or surface content; use ScenePointer, Rollout or the host for those.
