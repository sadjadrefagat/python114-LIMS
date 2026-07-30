import { useEffect, useRef, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

export default function Languages() {
  const empty = { name: '' }
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [form, setForm] = useState(empty)
  const [editId, setEditId] = useState(null)
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const formPanelRef = useRef(null)
  const nameInputRef = useRef(null)
  const paging = useClientPagination(rows)

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
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  function reset() {
    setEditId(null)
    setForm(empty)
  }

  function startEdit(row) {
    const id = Number(row.Id)
    setEditId(id)
    setForm({ name: row.Name || '' })
    setMessage('')
    setError('')
    requestAnimationFrame(() => {
      formPanelRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
      nameInputRef.current?.focus()
      nameInputRef.current?.select()
    })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    const currentId = editId
    const name = form.name.trim()
    if (!name) {
      setError('نام زبان را وارد کنید')
      return
    }

    setBusy(true)
    setMessage('')
    setError('')
    try {
      const payload = { name }
      if (currentId) {
        await api.put(`/languages/${currentId}`, payload)
        setMessage('زبان ویرایش شد')
      } else {
        await api.post('/languages', payload)
        setMessage('زبان ثبت شد')
      }
      reset()
      await load(search)
    } catch (err) {
      setError(err.message || 'خطا در ذخیره زبان')
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    const ok = await askConfirm({
      title: 'حذف زبان',
      message: 'با حذف این زبان، در صورت وابستگی به سطح یا دوره ممکن است عملیات رد شود.',
      confirmLabel: 'حذف زبان',
      details: [
        { label: 'نام زبان', value: row.Name },
        { label: 'شناسه', value: row.Id },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/languages/${row.Id}`)
      setMessage('زبان حذف شد')
      if (editId === row.Id || editId === Number(row.Id)) reset()
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

      <div
        className={`create-panel ${editId ? 'is-editing' : ''}`}
        ref={formPanelRef}
      >
        <div className="d-flex justify-content-between align-items-center mb-3">
          <h2 className="h6 fw-bold mb-0">
            {editId ? `ویرایش زبان #${editId}` : 'ثبت زبان جدید'}
          </h2>
          {editId && (
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={reset}>
              انصراف از ویرایش
            </button>
          )}
        </div>
        <form className="row g-2 align-items-end" onSubmit={handleSubmit}>
          <div className="col-md-8">
            <label className="form-label">نام زبان</label>
            <input
              ref={nameInputRef}
              className="form-control"
              value={form.name}
              onChange={(e) => setForm({ name: e.target.value })}
              required
              maxLength={50}
            />
          </div>
          <div className="col-md-4 d-grid">
            <button type="submit" className="btn btn-brand rounded-pill" disabled={busy}>
              {busy ? '...' : editId ? 'ذخیره تغییرات' : 'ثبت زبان'}
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
          <table className="table table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>نام</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id} className={editId === Number(row.Id) ? 'table-row-editing' : undefined}>
                  <td>{row.Id}</td>
                  <td>{row.Name}</td>
                  <td className="text-nowrap">
                    <RowActions onEdit={() => startEdit(row)} onDelete={() => handleDelete(row)} />
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
