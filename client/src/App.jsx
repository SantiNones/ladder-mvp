import { useEffect, useState } from 'react'
import { LENSES, fetchMe } from './api.js'
import LensBar from './components/LensBar.jsx'
import MyLadder from './components/MyLadder.jsx'
import MyTeam from './components/MyTeam.jsx'

const DEFAULT_LENS_ID = LENSES[0].id

export default function App() {
  const [lensId, setLensId] = useState(DEFAULT_LENS_ID)
  const [me, setMe] = useState(null)
  const [meError, setMeError] = useState(null)
  const [page, setPage] = useState('ladder')
  const [ladderSnapshotId, setLadderSnapshotId] = useState(null)

  useEffect(() => {
    let cancelled = false
    setMeError(null)

    fetchMe(lensId)
      .then((data) => {
        if (cancelled) return
        setMe(data)
        setLadderSnapshotId(data.latest_snapshot_id)
        setPage(data.role === 'manager' ? 'team' : 'ladder')
      })
      .catch(() => {
        if (cancelled) return
        setMe(null)
        setMeError('Could not load viewer. Is the API running and seeded?')
      })

    return () => {
      cancelled = true
    }
  }, [lensId])

  function handleLensChange(nextId) {
    setLensId(nextId)
  }

  function openReportLadder(snapshotId) {
    setLadderSnapshotId(snapshotId)
    setPage('ladder')
  }

  function openOwnLadder() {
    setLadderSnapshotId(me?.latest_snapshot_id ?? null)
    setPage('ladder')
  }

  const isManager = me?.role === 'manager'

  return (
    <div className="app-shell">
      <LensBar lenses={LENSES} activeId={lensId} onChange={handleLensChange} />

      {meError && <p className="banner-error">{meError}</p>}

      {me && (
        <>
          <nav className="app-nav" aria-label="Primary">
            <button
              type="button"
              className={page === 'ladder' ? 'nav-button nav-button--active' : 'nav-button'}
              onClick={openOwnLadder}
            >
              My ladder
            </button>
            {isManager && (
              <button
                type="button"
                className={page === 'team' ? 'nav-button nav-button--active' : 'nav-button'}
                onClick={() => setPage('team')}
              >
                My team
              </button>
            )}
          </nav>

          <main className="app-main">
            {page === 'ladder' && (
              <MyLadder
                personId={lensId}
                snapshotId={ladderSnapshotId}
                viewerName={me.name}
              />
            )}
            {page === 'team' && isManager && (
              <MyTeam reports={me.reports} onOpenLadder={openReportLadder} />
            )}
          </main>
        </>
      )}
    </div>
  )
}
