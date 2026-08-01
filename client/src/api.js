const LENSES = [
  { id: 2, name: 'Ana Ferrer', roleLabel: 'Employee' },
  { id: 1, name: 'Laura Puig', roleLabel: 'Manager' },
]

async function apiGet(path, personId) {
  const response = await fetch(`/api${path}`, {
    headers: { 'X-Person-Id': String(personId) },
  })
  if (!response.ok) {
    const error = new Error(`Request failed: ${response.status}`)
    error.status = response.status
    throw error
  }
  return response.json()
}

export function fetchMe(personId) {
  return apiGet('/me', personId)
}

export function fetchSnapshot(snapshotId, personId) {
  return apiGet(`/snapshots/${snapshotId}`, personId)
}

export function fetchProgress(personId) {
  return apiGet(`/people/${personId}/progress`, personId)
}

export { LENSES }
