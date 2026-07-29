import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker from '../components/JalaliDatePicker'

export default function Students() {
  const [rows, setRows] = useState([])
  const [languages, setLanguages] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [form, setForm] = useState({
    first_name: '',
    last_name: '',
    father_name: '',
    national_code: '',
    gender: '1',
    birth_date: '',
    mobile: '',
    email: '',
    target_language_ref: '',
  })

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
  }, [search])

  async function handleCreate(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
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
      setShowCreate(false)
      setForm({
        first_name: '',
        last_name: '',
        father_name: '',
        national_code: '',
        gender: '1',
        birth_date: '',
        mobile: '',
        email: '',
        target_language_ref: '',
      })
      await load('')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
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
          <button className="btn btn-brand rounded-pill" onClick={() => setShowCreate((v) => !v)}>
            {showCreate ? 'بستن' : 'زبان‌آموز جدید'}
          </button>
        </div>
      </div>

      {showCreate && (
        <div className="create-panel">
          <form className="row g-2" onSubmit={handleCreate}>
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
              <JalaliDatePicker required value={form.birth_date} onChange={(v) => setForm((p) => ({ ...p, birth_date: v }))} />
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
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>{busy ? '...' : 'ثبت زبان‌آموز'}</button>
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
