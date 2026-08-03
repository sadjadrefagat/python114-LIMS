import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, { todayJalaliString } from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'
import { isValidMobile, MOBILE_ERROR, MOBILE_HINT, normalizeMobileInput } from '../utils/mobile'

const emptyForm = {
  first_name: '',
  last_name: '',
  father_name: '',
  national_code: '',
  gender: '1',
  birth_date: '',
  mobile: '',
  email: '',
  target_language_ref: '',
}

export default function Students() {
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [languages, setLanguages] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [selected, setSelected] = useState(() => new Set())
  const today = useMemo(() => todayJalaliString(), [])
  const [form, setForm] = useState(emptyForm)
  const paging = useClientPagination(rows)

  useEffect(() => {
    api.get('/languages').then((d) => setLanguages(d.languages || [])).catch(() => {})
  }, [])

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const data = await api.get(`/students${query}`)
      setRows(data.students || [])
      setSelected(new Set())
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

  const pageIds = useMemo(() => paging.slice.map((r) => r.Id), [paging.slice])
  const allPageSelected = pageIds.length > 0 && pageIds.every((id) => selected.has(id))
  const somePageSelected = pageIds.some((id) => selected.has(id))

  function toggleOne(id) {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function togglePage() {
    setSelected((prev) => {
      const next = new Set(prev)
      if (allPageSelected) {
        pageIds.forEach((id) => next.delete(id))
      } else {
        pageIds.forEach((id) => next.add(id))
      }
      return next
    })
  }

  function resetForm() {
    setEditId(null)
    setForm(emptyForm)
    setShowCreate(false)
  }

  function startEdit(row) {
    setEditId(row.Id)
    setForm({
      first_name: row.FirstName || '',
      last_name: row.LastName || '',
      father_name: row.FatherName || '',
      national_code: row.NationalCode || '',
      gender: String(row.Gender ?? '1'),
      birth_date: row.BirthDate || '',
      mobile: row.Mobile || '',
      email: row.Email || '',
      target_language_ref: row.TargetLanguageRef ? String(row.TargetLanguageRef) : '',
    })
    setShowCreate(true)
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')

    if (!isValidMobile(form.mobile)) {
      setError(MOBILE_ERROR)
      setBusy(false)
      return
    }

    try {
      if (editId) {
        await api.put(`/students/${editId}`, {
          first_name: form.first_name.trim(),
          last_name: form.last_name.trim(),
          father_name: form.father_name.trim() || null,
          national_code: form.national_code.trim(),
          gender: Number(form.gender),
          birth_date: form.birth_date || null,
          mobile: form.mobile.trim(),
          email: form.email.trim() || null,
          target_language_ref: form.target_language_ref ? Number(form.target_language_ref) : null,
        })
        setMessage('زبان‌آموز ویرایش شد')
      } else {
        await api.post('/students', {
          first_name: form.first_name.trim(),
          last_name: form.last_name.trim(),
          father_name: form.father_name.trim(),
          national_code: form.national_code.trim(),
          gender: Number(form.gender),
          birth_date: form.birth_date,
          mobile: form.mobile.trim(),
          email: form.email.trim() || null,
          target_language_ref: form.target_language_ref ? Number(form.target_language_ref) : null,
          preferred_ui_language: 'fa',
          notifications_enabled: true,
        })
        setMessage('زبان‌آموز ثبت شد')
      }
      resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    const ok = await askConfirm({
      title: 'حذف زبان‌آموز',
      message: 'این زبان‌آموز آرشیو می‌شود و از فهرست فعال خارج خواهد شد.',
      confirmLabel: 'آرشیو زبان‌آموز',
      cancelLabel: 'بازگشت',
      details: [
        { label: 'نام', value: `${row.FirstName || ''} ${row.LastName || ''}`.trim() },
        { label: 'موبایل', value: row.Mobile },
        { label: 'زبان هدف', value: row.TargetLanguageName },
        { label: 'کد ملی', value: row.NationalCode },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/students/${row.Id}`)
      setMessage('زبان‌آموز آرشیو شد')
      if (editId === row.Id) resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    }
  }

  async function handleBulkDelete() {
    const ids = [...selected]
    if (!ids.length) return
    const names = rows
      .filter((r) => selected.has(r.Id))
      .slice(0, 8)
      .map((r) => `${r.FirstName} ${r.LastName}`)
    const ok = await askConfirm({
      title: 'حذف گروهی از پایگاه داده',
      message:
        `${ids.length} زبان‌آموز به‌همراه ثبت‌نام‌ها، پرداخت‌ها، نمرات و حضور مرتبط برای همیشه از پایگاه داده حذف می‌شوند. این کار قابل بازگشت نیست.`,
      confirmLabel: 'حذف قطعی',
      cancelLabel: 'بازگشت',
      details: [
        { label: 'تعداد', value: String(ids.length) },
        {
          label: 'نمونه',
          value: names.length
            ? `${names.join('، ')}${ids.length > names.length ? ' …' : ''}`
            : null,
        },
      ],
    })
    if (!ok) return
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const res = await api.post('/students/bulk-delete', { ids })
      setMessage(res.message || `${res.deleted || ids.length} زبان‌آموز حذف شد`)
      if (editId && selected.has(editId)) resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex flex-wrap justify-content-between gap-3">
        <div>
          <h1 className="section-title h3 mb-1">زبان‌آموزان</h1>
          <p className="muted mb-0">فهرست و ثبت زبان‌آموز</p>
        </div>
        <div className="d-flex flex-wrap gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 240 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          {selected.size > 0 && (
            <button
              type="button"
              className="btn btn-outline-danger rounded-pill"
              disabled={busy}
              onClick={handleBulkDelete}
            >
              حذف انتخاب‌شده‌ها ({selected.size})
            </button>
          )}
          <button
            className="btn btn-brand rounded-pill"
            onClick={() => (showCreate ? resetForm() : setShowCreate(true))}
          >
            {showCreate ? 'بستن' : 'زبان‌آموز جدید'}
          </button>
        </div>
      </div>

      {showCreate && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش زبان‌آموز #${editId}` : 'ثبت زبان‌آموز جدید'}
            </h2>
            {editId && (
              <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
                انصراف
              </button>
            )}
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">نام</label>
              <input className="form-control" value={form.first_name} onChange={(e) => setForm((p) => ({ ...p, first_name: e.target.value }))} required />
            </div>
            <div className="col-md-4">
              <label className="form-label">نام خانوادگی</label>
              <input className="form-control" value={form.last_name} onChange={(e) => setForm((p) => ({ ...p, last_name: e.target.value }))} required />
            </div>
            <div className="col-md-4">
              <label className="form-label">نام پدر</label>
              <input className="form-control" value={form.father_name} onChange={(e) => setForm((p) => ({ ...p, father_name: e.target.value }))} required />
            </div>
            <div className="col-md-4">
              <label className="form-label">کد ملی</label>
              <input className="form-control" value={form.national_code} onChange={(e) => setForm((p) => ({ ...p, national_code: e.target.value.replace(/\D/g, '').slice(0, 10) }))} maxLength={10} required />
            </div>
            <div className="col-md-4">
              <label className="form-label">موبایل</label>
              <input
                className="form-control"
                value={form.mobile}
                onChange={(e) => setForm((p) => ({ ...p, mobile: normalizeMobileInput(e.target.value) }))}
                placeholder="09123456789"
                inputMode="numeric"
                maxLength={11}
                pattern="09[0-9]{9}"
                title={MOBILE_HINT}
                required
              />
              <div className="form-text">{MOBILE_HINT}</div>
            </div>
            <div className="col-md-4">
              <label className="form-label">تاریخ تولد شمسی</label>
              <JalaliDatePicker
                required
                value={form.birth_date}
                onChange={(v) => setForm((p) => ({ ...p, birth_date: v }))}
                maxDate={today}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">جنسیت</label>
              <VazirSelect value={form.gender} onChange={(v) => setForm((p) => ({ ...p, gender: v }))} options={[{ value: '1', label: 'خانم' }, { value: '2', label: 'آقا' }]} />
            </div>
            <div className="col-md-4">
              <label className="form-label">زبان هدف</label>
              <VazirSelect
                value={form.target_language_ref}
                onChange={(v) => setForm((p) => ({ ...p, target_language_ref: v }))}
                placeholder="اختیاری"
                options={languages.map((l) => ({ value: String(l.Id), label: l.Name }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">ایمیل</label>
              <input className="form-control" value={form.email} onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))} />
            </div>
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره' : 'ثبت زبان‌آموز'}
              </button>
            </div>
          </form>
        </div>
      )}

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-hover table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th style={{ width: 42 }}>
                  <input
                    type="checkbox"
                    className="form-check-input"
                    checked={allPageSelected}
                    ref={(el) => {
                      if (el) el.indeterminate = !allPageSelected && somePageSelected
                    }}
                    onChange={togglePage}
                    title="انتخاب همه در این صفحه"
                    aria-label="انتخاب همه در این صفحه"
                  />
                </th>
                <th>نام</th>
                <th>کد ملی</th>
                <th>موبایل</th>
                <th>زبان هدف</th>
                <th>سطح</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id} className={selected.has(row.Id) ? 'table-row-selected' : undefined}>
                  <td>
                    <input
                      type="checkbox"
                      className="form-check-input"
                      checked={selected.has(row.Id)}
                      onChange={() => toggleOne(row.Id)}
                      aria-label={`انتخاب ${row.FirstName} ${row.LastName}`}
                    />
                  </td>
                  <td>
                    {row.FirstName} {row.LastName}
                  </td>
                  <td>{row.NationalCode}</td>
                  <td>{row.Mobile}</td>
                  <td>{row.TargetLanguageName || '—'}</td>
                  <td>{row.CurrentLevelName || '—'}</td>
                  <td className="text-nowrap">
                    <RowActions onEdit={() => startEdit(row)} onDelete={() => handleDelete(row)} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">موردی یافت نشد.</div>}
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
