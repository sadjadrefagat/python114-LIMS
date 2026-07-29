import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'

export default function Languages() {
  const empty = { name: '' }
  const [rows, setRows] = useState([])
  const [form, setForm] = useState(empty)
  const [editId, setEditId] = useState(null)
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const data = await api.get(`/languages${query}`)
      setRows(data.languages || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const t = setTimeout(() => load(search), 250)
    return () => clearTimeout(t)
  }, [search])

  function reset() {
    setEditId(null)
    setForm(empty)
  }

  function startEdit(row) {
    setEditId(row.Id)
    setForm({ name: row.Name || '' })
    setMessage('')
    setError('')
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setMessage('')
    setError('')
    try {
      const payload = { name: form.name.trim() }
      if (editId) await api.put(`/languages/${editId}`, payload)
      else await api.post('/languages', payload)
      setMessage(editId ? 'زبان ویرایش شد' : 'زبان ثبت شد')
      reset()
      await load('')
      setSearch('')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    if (!window.confirm(`حذف زبان «${row.Name}»؟`)) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/languages/${row.Id}`)
      setMessage('زبان حذف شد')
      if (editId === row.Id) reset()
      await load(search)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">زبان‌ها</h1>
          <p className="muted mb-0">ثبت، ویرایش، حذف و جستجو</p>
        </div>
        <input
          className="form-control"
          style={{ maxWidth: 240 }}
          placeholder="جستجو..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <div className="create-panel">
        <div className="d-flex justify-content-between align-items-center mb-3">
          <h2 className="h6 fw-bold mb-0">{editId ? `ویرایش زبان #${editId}` : 'ثبت زبان جدید'}</h2>
          {editId && (
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={reset}>
              انصراف
            </button>
          )}
        </div>
        <form className="row g-2 align-items-end" onSubmit={handleSubmit}>
          <div className="col-md-8">
            <label className="form-label">نام زبان</label>
            <input
              className="form-control"
              value={form.name}
              onChange={(e) => setForm({ name: e.target.value })}
              required
            />
          </div>
          <div className="col-md-4 d-grid">
            <button className="btn btn-brand rounded-pill" disabled={busy}>
              {busy ? '...' : editId ? 'ذخیره' : 'ثبت زبان'}
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
                <th></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.Name}</td>
                  <td className="text-nowrap">
                    <button type="button" className="btn btn-sm btn-outline-success rounded-pill me-1" onClick={() => startEdit(row)}>
                      ویرایش
                    </button>
                    <button type="button" className="btn btn-sm btn-outline-danger rounded-pill" onClick={() => handleDelete(row)}>
                      حذف
                    </button>
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={3} className="text-center muted py-4">
                    موردی یافت نشد
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
