# Capsule

A compact labeled action, selection or status control for panel tabs and popout commands; the host owns active and any in-progress state.
states: rest, hover, press, focus, disabled and active; active is lavender identity over the current surface, focus rings the outer pill, disabled dims each painted role through Style.disabled rather than composite opacity.
actions: pointer click, Space, Enter and the actions entry call activate() and emit clicked; active never changes inside the component.
pointer: the full pill is the target and reports a hand; wheel does not claim the event.
keyboard: tab reaches an enabled capsule, click takes focus, and Space/Enter activate the same route.
screen reader: Accessible.Button names the label; detail is supporting information, not a second action.
size: sm, md and lg use the control-height scale; icon, type and insets scale as their own roles, while radius and focus gap remain constant.
tokens: controlHeight, icon scale, text scale, space scale, surface ladder, accent, danger, Motion and StateLayer; no local colors or measurements.
motion: subdued capsule hover and press response plus color settling; reduced motion shortens the duration, never invents another state.
not designed: asynchronous progress, confirmation and menu disclosure; callers state progress in label/detail and surfaces own the next layer.
