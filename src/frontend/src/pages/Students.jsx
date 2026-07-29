import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, { todayJalaliString } from '../components/JalaliDatePicker'

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
  const [rows, setRows] = useState([])
  const [languages, setLanguages] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const today = useMemo(() => todayJalaliString(), [])
  const [form, setForm] = useState(emptyForm)

  useEffect(() => {
    api.get('/languages').then((d) => setLanguages(d.languages || [])).catch(() => {})
  }, [])

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const data = await api.get(`/students${query}`)
      setRows(data.students || [])
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
    if (!window.confirm(`حذف زبان‌آموز «${row.FirstName} ${row.LastName}»؟`)) return
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

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between gap-3">
        <div>
          <h1 className="section-title h3 mb-1">زبان‌آموزان</h1>
          <p className="muted mb-0">فهرست و ثبت زبان‌آموز</p>
        </div>
        <div className="d-flex gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 240 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
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
              <input className="form-control" value={form.mobile} onChange={(e) => setForm((p) => ({ ...p, mobile: e.target.value }))} required />
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
          <table className="table table-hover mb-0 align-middle">
            <thead>
              <tr>
                <th>نام</th>
                <th>کد ملی</th>
                <th>موبایل</th>
                <th>زبان هدف</th>
                <th>سطح</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>
                    {row.FirstName} {row.LastName}
                  </td>
                  <td>{row.NationalCode}</td>
                  <td>{row.Mobile}</td>
                  <td>{row.TargetLanguageName || '—'}</td>
                  <td>{row.CurrentLevelName || '—'}</td>
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
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">موردی یافت نشد.</div>}
        </div>
      )}
    </div>
  )
}
