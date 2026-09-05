import type { ReactNode, CSSProperties } from 'react'
import { Icon, type IconName } from './Icon'
import { REFERENCE_IDS, REFERENCE_TITLES, type ReferenceId } from './references'

type Sample = { state: string; className?: string; node: ReactNode }

const stateClass = (base: string, state: string) => `${base}${state === 'resting' ? '' : ` ${base}--${state}`}`

function cardSamples(): Sample[] {
  return ['resting', 'hover', 'pressed', 'disabled'].map((state) => ({
    state,
    className: stateClass('ref-card', state),
    node: <span>Card</span>,
  }))
}

function capsuleSamples(): Sample[] {
  return ['resting', 'hover', 'pressed', 'disabled', 'active'].map((state) => ({
    state,
    className: stateClass('ref-capsule', state),
    node: <><Icon name="bell" /><span>Notifications</span><b>2</b></>,
  }))
}

function stateLayerSamples(): Sample[] {
  return ['resting', 'hover', 'pressed', 'disabled'].map((state) => ({
    state,
    className: stateClass('ref-state-layer', state),
    node: <><span className="ref-state-layer__target" /><span className="ref-state-layer__label">StateLayer / {state}</span></>,
  }))
}

function svgIconSamples(): Sample[] {
  return ['resting', 'hover', 'pressed', 'disabled', 'selected'].map((state) => ({
    state,
    className: stateClass('ref-svg-icon', state),
    node: <Icon name="theme" />,
  }))
}

function iconButtonSamples(): Sample[] {
  return ['resting', 'hover', 'pressed', 'disabled'].map((state) => ({
    state,
    className: stateClass('ref-icon-button', state),
    node: <Icon name="theme" />,
  }))
}

function levelSamples(): Sample[] {
  const levels: { state: string; width: string; disabled?: boolean }[] = [
    { state: 'resting', width: '42%' },
    { state: 'high', width: '82%' },
    { state: 'disabled', width: '42%', disabled: true },
  ]
  return levels.map(({ state, width, disabled }) => ({
    state,
    className: disabled ? 'ref-level ref-level--disabled' : 'ref-level',
    node: <div className="reference-level"><i /><b style={{ width }} /><span className="reference-level__thumb" style={{ left: width }} /></div>,
  }))
}

function proseSamples(): Sample[] {
  return ['hero', 'display', 'heading', 'title', 'body', 'label', 'metadata', 'reading', 'section'].map((state) => ({
    state,
    className: `ref-prose ref-prose--${state}`,
    node: <span>{state === 'reading' ? '72%' : 'The quick brown fox'}</span>,
  }))
}

function popoutRowSamples(): Sample[] {
  return ['resting', 'hover', 'pressed', 'disabled', 'selected'].map((state) => ({
    state,
    className: stateClass('ref-row', state),
    node: <><Icon name="network" /><span>qsm-lab</span><small>Connected</small></>,
  }))
}

const WEEKDAYS = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']

function calendarCells(shown: Date): ReactNode[] {
  const today = new Date(2026, 7, 28)
  const first = new Date(shown.getFullYear(), shown.getMonth(), 1)
  const cells: ReactNode[] = []
  for (let index = 0; index < 42; index += 1) {
    const date = new Date(first.getFullYear(), first.getMonth(), 1 - ((first.getDay() + 6) % 7) + index)
    const inMonth = date.getMonth() === shown.getMonth()
    const isToday = date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate()
    cells.push(
      <i
        key={index}
        className={`ref-calendar__day${inMonth ? '' : ' ref-calendar__day--muted'}${isToday ? ' ref-calendar__day--today' : ''}`}
      >
        {date.getDate()}
      </i>,
    )
  }
  return cells
}

function monthCalendarSamples(): Sample[] {
  return [
    { state: 'august-2026', shown: new Date(2026, 7, 1) },
    { state: 'september-2026', shown: new Date(2026, 8, 1) },
  ].map(({ state, shown }) => ({
    state,
    className: 'ref-calendar',
    node: (
      <div className="ref-calendar">
        <div className="ref-calendar__head">{shown.toLocaleString('en-US', { month: 'long', year: 'numeric' })}</div>
        <div className="ref-calendar__grid">
          {WEEKDAYS.map((day) => <span key={day} className="ref-calendar__weekday">{day}</span>)}
          {calendarCells(shown)}
        </div>
      </div>
    ),
  }))
}

function searchSamples(): Sample[] {
  const searches: { state: string; className?: string; value?: string; disabled?: boolean }[] = [
    { state: 'resting' },
    { state: 'hover', className: 'ref-search--hover' },
    { state: 'focused', className: 'ref-search--focus' },
    { state: 'filled', className: 'ref-search--focus', value: 'qsm-shell' },
    { state: 'disabled', className: 'ref-search--disabled', disabled: true },
  ]
  return searches.map(({ state, className, value, disabled }) => ({
    state,
    className: className ?? '',
    node: (
      <label className={`ref-search${className ? ` ${className}` : ''}`}>
        <Icon name="apps" />
        <input placeholder="Search components" defaultValue={value} disabled={disabled} />
      </label>
    ),
  }))
}

function resultSamples(): Sample[] {
  return [
    { state: 'idle' },
    { state: 'selected', className: 'ref-result--selected' },
    { state: 'header', className: 'ref-result--header' },
  ].map(({ state, className }) => ({
    state,
    className: className ?? '',
    node: state === 'header'
      ? <div className="ref-result-header"><span><i /><span>Tools</span><i /></span></div>
      : <div className="ref-result"><span><b>Pick a colour</b><small>Open colour picker</small></span></div>,
  }))
}

function menuRowItemSamples(): Sample[] {
  return ['resting', 'selected', 'danger', 'header', 'separator', 'disabled'].map((state) => ({
    state,
    className: '',
    node: state === 'header'
      ? <div className="ref-result-header"><span><i /><span>Section</span><i /></span></div>
      : state === 'separator'
        ? <div className="ref-divider" />
        : <span className={`ref-row${state === 'resting' ? '' : ` ref-row--${state}`}`}><Icon name="theme" /><span>Menu item</span></span>,
  }))
}

function menuSamples(): Sample[] {
  const selected = (i: number) => `ref-row${i === 1 ? ' ref-row--selected' : ''}`
  return ['resting', 'selected'].map((state) => ({
    state,
    className: '',
    node: (
      <div className="ref-card" style={{ display: 'grid', gap: 2 }}>
        <span className={selected(0)}><Icon name="theme" /><span>Pick a colour</span></span>
        <span className={selected(1)}><Icon name="network" /><span>Copy</span></span>
        <span className="ref-result-header"><span><i /><span>Danger zone</span><i /></span></span>
        <span className="ref-row ref-row--danger"><Icon name="power" /><span>Clear</span></span>
      </div>
    ),
  }))
}

function osdSliderSamples(): Sample[] {
  const widths: Record<string, string> = { resting: '42%', high: '82%', muted: '42%', disabled: '42%' }
  return ['resting', 'high', 'muted', 'disabled'].map((state) => ({
    state,
    className: '',
    node: (
      <div className="reference-level" style={{ opacity: state === 'disabled' ? 0.35 : 1 }}>
        <i />
        <b style={{ width: widths[state] }} />
      </div>
    ),
  }))
}

function notificationSamples(): Sample[] {
  return ['resting', 'selected', 'expanded'].map((state) => ({
    state,
    className: '',
    node: (
      <div className={`ref-card${state !== 'resting' ? ` ref-card--${state}` : ''}`}>
        <Icon name="bell" />
        <span>Notification</span>
      </div>
    ),
  }))
}

function sessionButtonSamples(): Sample[] {
  return ['resting', 'selected', 'armed'].map((state) => ({
    state,
    className: '',
    node: (
      <span className={`ref-capsule${state !== 'resting' ? ` ref-capsule--${state}` : ''}`}>
        <Icon name="power" />
        <span>Power off</span>
      </span>
    ),
  }))
}

function tabsSamples(): Sample[] {
  const labels = ['Overview', 'Media', 'Performance']
  const states = ['first', 'second', 'third']
  return labels.map((_label, i) => ({
    state: states[i],
    className: '',
    node: (
      <div className="panel-tabs">
        {labels.map((l, j) => (
          <button key={l} className={`panel-tab${j === i ? ' panel-tab--active' : ''}`}>{l}</button>
        ))}
      </div>
    ),
  }))
}

function statRingSamples(): Sample[] {
  const rings = [
    { state: 'cpu', pct: '72%', label: 'CPU' },
    { state: 'memory', pct: '54%', label: 'MEM' },
    { state: 'disk', pct: '38%', label: 'DISK' },
  ]
  return rings.map(({ state, pct, label }) => ({
    state,
    className: '',
    node: (
      <div className="ref-stat-ring" style={{ ['--pct']: pct } as CSSProperties}>{label}</div>
    ),
  }))
}

function dividerSamples(): Sample[] {
  return ['default', 'inset', 'strong'].map((state) => ({
    state,
    className: '',
    node: <div className={`ref-divider${state === 'default' ? '' : ` ref-divider--${state}`}`} />,
  }))
}

function emptyStateSamples(): Sample[] {
  return ['default'].map((state) => ({
    state,
    className: '',
    node: (
      <div className="ref-card" style={{ display: 'grid', placeItems: 'center', gap: 4 }}>
        <Icon name="bell" />
        <span>Nothing here</span>
      </div>
    ),
  }))
}

function keyValueSamples(): Sample[] {
  const rows: { state: string; icon: IconName; label: string; value: string }[] = [
    { state: 'battery', icon: 'battery', label: 'Battery', value: '68%' },
    { state: 'wifi', icon: 'network', label: 'Wi-Fi', value: 'Connected' },
    { state: 'cpu', icon: 'apps', label: 'CPU', value: '72%' },
  ]
  return rows.map(({ state, icon, label, value }) => ({
    state,
    className: '',
    node: (
      <span className="ref-row">
        <Icon name={icon} />
        <span>{label}</span>
        <small>{value}</small>
      </span>
    ),
  }))
}

const SAMPLES: Record<ReferenceId, Sample[]> = {
  card: cardSamples(),
  capsule: capsuleSamples(),
  'state-layer': stateLayerSamples(),
  'svg-icon': svgIconSamples(),
  'icon-button': iconButtonSamples(),
  level: levelSamples(),
  prose: proseSamples(),
  'device-row': popoutRowSamples(),
  calendar: monthCalendarSamples(),
  search: searchSamples(),
  'result-row': resultSamples(),
  'osd-slider': osdSliderSamples(),
  notification: notificationSamples(),
  'session-button': sessionButtonSamples(),
  menu: menuSamples(),
  'list-row': menuRowItemSamples(),
  segmented: tabsSamples(),
  'stat-ring': statRingSamples(),
  divider: dividerSamples(),
  'empty-state': emptyStateSamples(),
  'key-value': keyValueSamples(),
}

// Deterministic primitive reference. All meaningful states render as labeled
// samples in one URL; `&state=<state>` rings the matching sample. No pointer
// position is ever required to see a hover/pressed/disabled/selected state.
export function ComponentReference({ component, state }: { component: string | null; state: string | null }) {
  if (!component || !REFERENCE_IDS.includes(component as ReferenceId)) return null
  const samples = SAMPLES[component as ReferenceId]
  return (
    <section className="component-reference" aria-label="Component reference">
      <p className="surface-label">Primitive reference</p>
      <h2>{REFERENCE_TITLES[component as ReferenceId]}</h2>
      <div className="reference-samples">
        {samples.map((sample) => (
          <figure
            key={sample.state}
            className={`reference-sample ${sample.className ?? ''}${sample.state === state ? ' reference-sample--focus' : ''}`}
            data-state={sample.state}
          >
            {sample.node}
            <figcaption>{sample.state}</figcaption>
          </figure>
        ))}
      </div>
    </section>
  )
}
