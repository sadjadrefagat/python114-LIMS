import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'

const empty = {
  language_ref: '',
  code: '',
  name: '',
  sort_order: '1',
}

export default function Levels() {
  const [rows, setRows] = useState([])
  const [languages, setLanguages] = useState([])
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
      const [lv, lang] = await Promise.all([
        api.get(`/levels${query}`),
        api.get('/languages'),
      ])
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
    const t = setTimeout(() => load(search), 250)
    return () => clearTimeout(t)
  }, [search])

  function reset() {
    setEditId(null)
    setForm(empty)
  }

  function startEdit(row) {
    setEditId(row.Id)
    setForm({
      language_ref: String(row.LanguageRef || ''),
      code: row.Code || '',
      name: row.Name || '',
      sort_order: String(row.SortOrder ?? '1'),
    })
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const payload = {
        language_ref: Number(form.language_ref),
        code: form.code.trim(),
        name: form.name.trim(),
        sort_order: Number(form.sort_order) || 0,
      }
      if (editId) {
        await api.put(`/levels/${editId}`, payload)
        setMessage('سطح ویرایش شد')
      } else {
        await api.post('/levels', payload)
        setMessage('سطح ثبت شد')
      }
      reset()
      await load(search)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    if (!window.confirm(`حذف سطح «${row.Name}»؟`)) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/levels/${row.Id}`)
      setMessage('سطح آرشیو شد')
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
          <h1 className="section-title h3 mb-1">سطح‌ها</h1>
          <p className="muted mb-0">ساختار زبان ← سطح</p>
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
          <h2 className="h6 fw-bold mb-0">{editId ? `ویرایش سطح #${editId}` : 'ثبت سطح جدید'}</h2>
          {editId && (
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={reset}>
              انصراف
            </button>
          )}
        </div>
        <form className="row g-2" onSubmit={handleSubmit}>
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
              {busy ? '...' : editId ? 'ذخیره' : 'ثبت سطح'}
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
                <th></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.LanguageName}</td>
                  <td>{row.Code}</td>
                  <td>{row.Name}</td>
                  <td>{row.SortOrder}</td>
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
                  <td colSpan={5} className="text-center muted py-4">
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
