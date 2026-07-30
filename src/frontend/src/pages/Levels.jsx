import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const empty = {
  language_ref: '',
  code: '',
  name: '',
  sort_order: '1',
}

export default function Levels() {
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [languages, setLanguages] = useState([])
  const [form, setForm] = useState(empty)
  const [editId, setEditId] = useState(null)
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const paging = useClientPagination(rows)

  async function load(q = search) {
    setLoading(true)
    setError('')
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const [lvResult, langResult] = await Promise.allSettled([
        api.get(`/levels${query}`),
        api.get('/languages'),
      ])

      const errors = []
      if (lvResult.status === 'fulfilled') {
        setRows(lvResult.value.levels || [])
      } else {
        setRows([])
        errors.push(lvResult.reason?.message || 'دریافت سطح‌ها ناموفق بود')
      }

      if (langResult.status === 'fulfilled') {
        setLanguages(langResult.value.languages || [])
      } else {
        setLanguages([])
        errors.push(langResult.reason?.message || 'دریافت زبان‌ها ناموفق بود')
      }

      if (errors.length) setError(errors.join(' — '))
    } catch (err) {
      setError(err.message)
      setRows([])
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
    if (!form.language_ref) {
      setError('زبان را انتخاب کنید')
      return
    }
    if (!form.name.trim()) {
      setError('نام سطح را وارد کنید')
      return
    }
    if (!form.code.trim()) {
      setError('کد سطح را وارد کنید')
      return
    }

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
    const ok = await askConfirm({
      title: 'حذف سطح',
      message: 'این سطح آرشیو می‌شود و دیگر در فهرست فعال نمایش داده نمی‌شود.',
      confirmLabel: 'آرشیو سطح',
      details: [
        { label: 'نام سطح', value: row.Name },
        { label: 'کد', value: row.Code },
        { label: 'زبان', value: row.LanguageName },
        { label: 'ترتیب', value: row.SortOrder },
      ],
    })
    if (!ok) return
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
      {confirmDialog}
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
      {error && (
        <div className="alert alert-danger py-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
          <span>{error}</span>
          <button type="button" className="btn btn-sm btn-outline-danger rounded-pill" onClick={() => load(search)}>
            تلاش مجدد
          </button>
        </div>
      )}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-zebra mb-0 align-middle">
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
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.LanguageName}</td>
                  <td>{row.Code}</td>
                  <td>{row.Name}</td>
                  <td>{row.SortOrder}</td>
                  <td className="text-nowrap">
                    <RowActions onEdit={() => startEdit(row)} onDelete={() => handleDelete(row)} />
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
          <PaginationBar
            page={paging.page}
            totalPages={paging.totalPages}
            total={paging.total}
            pageSize={paging.pageSize}
            from={paging.from}
            to={paging.to}
            onChange={paging.setPage}
          />
        </div>
      )}
    </div>
  )
}
