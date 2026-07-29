import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'

export default function Languages() {
  const [rows, setRows] = useState([])
  const [name, setName] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function load() {
    setLoading(true)
    try {
      const data = await api.get('/languages')
      setRows(data.languages || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  async function handleCreate(e) {
    e.preventDefault()
    setBusy(true)
    setMessage('')
    setError('')
    try {
      await api.post('/languages', { name: name.trim() })
      setName('')
      setMessage('زبان با موفقیت ثبت شد')
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head">
        <h1 className="section-title h3 mb-1">زبان‌ها</h1>
        <p className="muted mb-0">ثبت و مشاهده زبان‌های آموزشی</p>
      </div>

      <div className="create-panel">
        <h2 className="h6 fw-bold mb-3">ثبت زبان جدید</h2>
        <form className="row g-2 align-items-end" onSubmit={handleCreate}>
          <div className="col-md-8">
            <label className="form-label">نام زبان</label>
            <input
              className="form-control"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>
          <div className="col-md-4 d-grid">
            <button className="btn btn-brand rounded-pill" disabled={busy}>
              {busy ? 'در حال ثبت...' : 'ثبت زبان'}
            </button>
          </div>
        </form>
      </div>

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>نام</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.Name}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
