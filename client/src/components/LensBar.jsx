export default function LensBar({ lenses, activeId, onChange }) {
  return (
    <header className="lens-bar">
      <div className="brand">
        <p className="brand-name">Ladder</p>
        <p className="brand-tag">Development gap against a published framework</p>
      </div>
      <div className="lens-controls" role="group" aria-label="View as">
        <span className="lens-label">View as</span>
        {lenses.map((lens) => (
          <button
            key={lens.id}
            type="button"
            className={
              lens.id === activeId ? 'lens-button lens-button--active' : 'lens-button'
            }
            onClick={() => onChange(lens.id)}
          >
            <span className="lens-role">{lens.roleLabel}</span>
            <span className="lens-name">{lens.name}</span>
          </button>
        ))}
      </div>
    </header>
  )
}
