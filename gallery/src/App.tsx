import { useReducer } from 'react'
import wallpaper from './assets/dark-rain-world.png'
import './App.css'
import { ComponentReference } from './ComponentReference'
import { Icon } from './Icon'

type Surface = 'none' | 'panel' | 'launcher' | 'network' | 'colours'

type State = {
  activeWorkspace: number
  noticeCount: number
  railPinned: boolean
  surface: Surface
  fullscreen: boolean
  focusMode: boolean
  monitors: 1 | 2
}

type Action =
  | { type: 'workspace'; value: number }
  | { type: 'notice' }
  | { type: 'pin' }
  | { type: 'surface'; value: Surface }

function initialState(scenario: string | null): State {
  switch (scenario) {
    case 'rail': return { activeWorkspace: 1, noticeCount: 0, railPinned: true, surface: 'none', fullscreen: false, focusMode: false, monitors: 1 }
    case 'osd': return { activeWorkspace: 1, noticeCount: 0, railPinned: false, surface: 'none', fullscreen: false, focusMode: false, monitors: 1 }
    case 'panel': return { activeWorkspace: 2, noticeCount: 4, railPinned: true, surface: 'panel', fullscreen: false, focusMode: false, monitors: 1 }
    case 'launcher': return { activeWorkspace: 1, noticeCount: 0, railPinned: false, surface: 'launcher', fullscreen: false, focusMode: false, monitors: 1 }
    case 'network': return { activeWorkspace: 3, noticeCount: 1, railPinned: true, surface: 'network', fullscreen: false, focusMode: false, monitors: 1 }
    case 'notifications': return { activeWorkspace: 1, noticeCount: 5, railPinned: false, surface: 'none', fullscreen: false, focusMode: false, monitors: 1 }
    case 'colour-rollout': return { activeWorkspace: 1, noticeCount: 0, railPinned: true, surface: 'colours', fullscreen: false, focusMode: false, monitors: 1 }
    case 'fullscreen': return { activeWorkspace: 1, noticeCount: 1, railPinned: false, surface: 'none', fullscreen: true, focusMode: false, monitors: 1 }
    case 'focus-mode': return { activeWorkspace: 1, noticeCount: 1, railPinned: false, surface: 'none', fullscreen: false, focusMode: true, monitors: 1 }
    case 'multi-monitor': return { activeWorkspace: 2, noticeCount: 1, railPinned: false, surface: 'panel', fullscreen: false, focusMode: false, monitors: 2 }
    case 'border': return { activeWorkspace: 1, noticeCount: 2, railPinned: false, surface: 'none', fullscreen: false, focusMode: false, monitors: 1 }
    default: return { activeWorkspace: 1, noticeCount: 2, railPinned: false, surface: 'none', fullscreen: false, focusMode: false, monitors: 1 }
  }
}

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'workspace': return { ...state, activeWorkspace: action.value }
    case 'notice': return { ...state, noticeCount: state.noticeCount + 1 }
    case 'pin': return { ...state, railPinned: !state.railPinned }
    case 'surface': return { ...state, surface: state.surface === action.value ? 'none' : action.value }
  }
}

function Rail({ state, dispatch }: { state: State; dispatch: React.Dispatch<Action> }) {
  const action = (value: Surface) => dispatch({ type: 'surface', value })
  return <aside className={`rail ${state.railPinned ? 'rail--pinned' : ''}`} aria-label="Desktop rail">
    <button className="rail-logo" onClick={() => action('launcher')} aria-label="Open launcher">q</button>
    <span className="rail-divider" />
    <div className="workspace-list" aria-label="Workspaces">
      {[1, 2, 3, 4].map((item) => <button className={`workspace ${state.activeWorkspace === item ? 'workspace--active' : ''}`} key={item} onClick={() => dispatch({ type: 'workspace', value: item })}><span>{item}</span></button>)}
    </div>
    <div className="rail-space" />
    <button className="rail-control" onClick={() => action('network')} aria-label="Network"><Icon name="network" /><span>Network</span></button>
    <button className="rail-control" onClick={() => action('panel')} aria-label="Battery"><Icon name="battery" /><span>68%</span></button>
    <button className="rail-control rail-control--pin" onClick={() => dispatch({ type: 'pin' })} aria-label="Pin rail"><Icon name="pin" /><span>{state.railPinned ? 'Pinned' : 'Pin rail'}</span></button>
    <button className="rail-power" aria-label="Session menu"><Icon name="power" /></button>
  </aside>
}

function MockWindows() {
  return <section className="mock-windows" aria-label="Mock desktop work area">
    <article className="mock-window mock-window--terminal">
      <header><span>Build</span><div className="window-actions"><i /><i /><i /></div></header>
      <div className="terminal-body"><p><b>$</b> gallery status</p><p className="terminal-ok">Scenarios, panel states and primitive references are ready.</p><p>Next: capture and visual comparison.</p><span className="cursor" /></div>
    </article>
    <article className="mock-window mock-window--canvas">
      <header><span>Component canvas</span><div className="window-actions"><i /><i /><i /></div></header>
      <div className="canvas-body"><Icon name="apps" /><p>Mocked desktop content keeps the shell legible without pretending to be a web app.</p></div>
    </article>
  </section>
}

function Notice({ count }: { count: number }) {
  return <aside className="notice" aria-label="Mock notification"><span className="notice-line" /><div><p>qsm-test</p><strong>Reference shell updated</strong><small>{count} notifications in history</small></div></aside>
}

function Launcher() {
  return <section className="surface surface--launcher" aria-label="Launcher">
    <label className="launcher-search"><span>Search</span><input autoFocus placeholder="Applications, actions, themes" /></label>
    <div className="launcher-results">
      <button className="launcher-row launcher-row--selected"><Icon name="terminal" /><b>Foot</b><span>Terminal</span></button>
      <button className="launcher-row"><Icon name="files" /><b>Files</b><span>Browse workspace</span></button>
      <button className="launcher-row"><Icon name="theme" /><b>Theme</b><span>Deep night</span></button>
    </div>
  </section>
}

function Panel() {
  return <section className="surface surface--panel" aria-label="Desktop panel">
    <nav className="panel-tabs"><button className="panel-tab panel-tab--active">Overview</button><button className="panel-tab">Media</button><button className="panel-tab">Performance</button><button className="panel-tab">Notifications</button></nav>
    <div className="panel-cards"><article><p>Today</p><strong>23:36</strong><span>Wednesday, calm and clear</span></article><article><p>Focus</p><strong>qsm-shell</strong><span>Component gallery is the active workspace.</span></article><article><p>System</p><strong>Quiet</strong><span>Everything is running normally.</span></article></div>
  </section>
}

function Network() {
  return <section className="surface surface--network" aria-label="Network popout"><p className="surface-label">Connection</p><h2>Network</h2><div className="network-row"><i className="online" />qsm-lab <span>Connected</span></div><div className="network-row"><i />nightshift <span>Available</span></div><button className="surface-button">Open network settings</button></section>
}

function Colours() {
  return <section className="surface surface--network surface--colours" aria-label="Colour rollout"><p className="surface-label">Quick actions / Colours</p><h2>Colour workspace</h2><div className="colour-swatch" /><strong>#C5A5E9</strong><div className="colour-row"><i /><i /><i /><i /></div><button className="surface-button">Copy accent</button></section>
}

function ActiveSurface({ surface }: { surface: Surface }) {
  if (surface === 'launcher') return <Launcher />
  if (surface === 'panel') return <Panel />
  if (surface === 'network') return <Network />
  if (surface === 'colours') return <Colours />
  return null
}

function Osd() {
  return <section className="osd" aria-label="Volume OSD">
    <Icon name="volume" />
    <div className="osd-track"><i style={{ width: '68%' }} /></div>
    <b>68%</b>
  </section>
}

function App() {
  const scenario = new URLSearchParams(window.location.search).get('scenario')
  const component = new URLSearchParams(window.location.search).get('component')
  const urlState = new URLSearchParams(window.location.search).get('state')
  const [state, dispatch] = useReducer(reducer, scenario, initialState)
  return <main className={`desktop ${state.fullscreen ? 'desktop--fullscreen' : ''} ${state.focusMode ? 'desktop--focus' : ''} ${state.monitors === 2 ? 'desktop--dual' : ''}`} style={{ '--wallpaper': `url(${wallpaper})` } as React.CSSProperties}>
    <div className="desktop-frame">
       {!state.fullscreen && <Rail state={state} dispatch={dispatch} />}
      <section className="desktop-viewport">
        <header className="desktop-handle"><span>qsm</span><button onClick={() => dispatch({ type: 'notice' })} aria-label="Create mock notification">+</button></header>
        <MockWindows />
         <ActiveSurface surface={state.surface} />
         <ComponentReference component={component} state={urlState} />
        {scenario === 'osd' && <Osd />}
        <Notice count={state.noticeCount} />
      </section>
    </div>
  </main>
}

export default App
