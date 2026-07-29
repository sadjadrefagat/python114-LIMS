import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'

export default function Levels() {
  const [rows, setRows] = useState([])
  const [languages, setLanguages] = useState([])
  const [form, setForm] = useState({
    language_ref: '',
    code: '',
    name: '',
    sort_order: '1',
  })
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function load() {
    setLoading(true)
    try {
      const [lv, lang] = await Promise.all([api.get('/levels'), api.get('/languages')])
      setRows(lv.levels || [])
      setLanguages(lang.languages || [])
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
    setError('')
    setMessage('')
    try {
      await api.post('/levels', {
        language_ref: Number(form.language_ref),
        code: form.code.trim(),
        name: form.name.trim(),
        sort_order: Number(form.sort_order) || 0,
      })
      setForm({ language_ref: '', code: '', name: '', sort_order: '1' })
      setMessage('سطح ثبت شد')
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
        <h1 className="section-title h3 mb-1">سطح‌ها</h1>
        <p className="muted mb-0">ساختار زبان ← سطح</p>
      </div>

      <div className="create-panel">
        <h2 className="h6 fw-bold mb-3">ثبت سطح جدید</h2>
        <form className="row g-2" onSubmit={handleCreate}>
          <div className="col-md-4">
            <label className="form-label">زبان</label>
            <VazirSelect
              required
              value={form.language_ref}
              onChange={(v) => setForm((p) => ({ ...p, language_ref: v }))}
              placeholder="انتخاب زبان"
              options={languages.map((l) => ({ value: String(l.Id), label: l.Name }))}
            />
          </div>
          <div className="col-md-2">
            <label className="form-label">کد</label>
            <input
              className="form-control"
              value={form.code}
              onChange={(e) => setForm((p) => ({ ...p, code: e.target.value }))}
              placeholder="A1"
              required
            />
          </div>
          <div className="col-md-4">
            <label className="form-label">نام</label>
            <input
              className="form-control"
              value={form.name}
              onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
              required
            />
          </div>
          <div className="col-md-2">
            <label className="form-label">ترتیب</label>
            <input
              type="number"
              className="form-control"
              value={form.sort_order}
              onChange={(e) => setForm((p) => ({ ...p, sort_order: e.target.value }))}
            />
          </div>
          <div className="col-12 d-grid d-md-block">
            <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
              {busy ? '...' : 'ثبت سطح'}
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
                <th>زبان</th>
                <th>کد</th>
                <th>نام</th>
                <th>ترتیب</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.LanguageName}</td>
                  <td>{row.Code}</td>
                  <td>{row.Name}</td>
                  <td>{row.SortOrder}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
