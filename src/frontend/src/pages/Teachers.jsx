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
  gender: '2',
  birth_date: '',
  mobile: '',
  email: '',
  specialty: '',
  bio: '',
}

export default function Teachers() {
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const today = useMemo(() => todayJalaliString(), [])
  const [form, setForm] = useState(emptyForm)

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const data = await api.get(`/teachers${query}`)
      setRows(data.teachers || [])
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
      gender: String(row.Gender ?? '2'),
      birth_date: row.BirthDate || '',
      mobile: row.Mobile || '',
      email: row.Email || '',
      specialty: row.Specialty || '',
      bio: row.Bio || '',
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
      const payload = {
        first_name: form.first_name.trim(),
        last_name: form.last_name.trim(),
        father_name: form.father_name.trim() || null,
        national_code: form.national_code.trim(),
        gender: Number(form.gender),
        birth_date: form.birth_date || null,
        mobile: form.mobile.trim(),
        email: form.email.trim() || null,
        specialty: form.specialty.trim(),
        bio: form.bio.trim() || null,
      }
      if (editId) {
        await api.put(`/teachers/${editId}`, payload)
        setMessage('مدرس ویرایش شد')
      } else {
        await api.post('/teachers', payload)
        setMessage('مدرس ثبت شد')
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
    if (!window.confirm(`حذف مدرس «${row.FirstName} ${row.LastName}»؟`)) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/teachers/${row.Id}`)
      setMessage('مدرس آرشیو شد')
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
          <h1 className="section-title h3 mb-1">مدرسان</h1>
          <p className="muted mb-0">لیست و ثبت مدرس</p>
        </div>
        <div className="d-flex gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 220 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button
            className="btn btn-brand rounded-pill"
            onClick={() => (showCreate ? resetForm() : setShowCreate(true))}
          >
            {showCreate ? 'بستن' : 'مدرس جدید'}
          </button>
        </div>
      </div>

      {showCreate && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش مدرس #${editId}` : 'ثبت مدرس جدید'}
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
              <input className="form-control" value={form.father_name} onChange={(e) => setForm((p) => ({ ...p, father_name: e.target.value }))} />
            </div>
            <div className="col-md-4">
              <label className="form-label">کد ملی</label>
              <input className="form-control" value={form.national_code} onChange={(e) => setForm((p) => ({ ...p, national_code: e.target.value.replace(/\D/g, '').slice(0, 10) }))} maxLength={10} required />
              <div className="form-text">۱۰ رقم معتبر (الگوریتم کد ملی)</div>
            </div>
            <div className="col-md-4">
              <label className="form-label">موبایل</label>
              <input className="form-control" value={form.mobile} onChange={(e) => setForm((p) => ({ ...p, mobile: e.target.value }))} required />
            </div>
            <div className="col-md-4">
              <label className="form-label">جنسیت</label>
              <VazirSelect value={form.gender} onChange={(v) => setForm((p) => ({ ...p, gender: v }))} options={[{ value: '1', label: 'خانم' }, { value: '2', label: 'آقا' }]} />
            </div>
            <div className="col-md-4">
              <label className="form-label">تاریخ تولد</label>
              <JalaliDatePicker
                value={form.birth_date}
                onChange={(v) => setForm((p) => ({ ...p, birth_date: v }))}
                maxDate={today}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">ایمیل</label>
              <input className="form-control" value={form.email} onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))} />
            </div>
            <div className="col-md-4">
              <label className="form-label">تخصص</label>
              <input className="form-control" value={form.specialty} onChange={(e) => setForm((p) => ({ ...p, specialty: e.target.value }))} required />
            </div>
            <div className="col-12">
              <label className="form-label">معرفی</label>
              <input className="form-control" value={form.bio} onChange={(e) => setForm((p) => ({ ...p, bio: e.target.value }))} />
            </div>
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره' : 'ثبت مدرس'}
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
        <div className="row g-3">
          {rows.map((row) => (
            <div className="col-md-6 col-lg-4" key={row.Id}>
              <div className="course-tile">
                <h2 className="h5 fw-bold mb-1">
                  {row.FirstName} {row.LastName}
                </h2>
                <p className="muted small mb-2">{row.Specialty || 'تخصص ثبت نشده'}</p>
                <div className="d-flex flex-wrap gap-2 mb-3">
                  {row.Mobile && <span className="chip chip-sky">{row.Mobile}</span>}
                  <span className="chip chip-teal">{row.Gender === 1 ? 'خانم' : 'آقا'}</span>
                </div>
                <div className="d-flex gap-1">
                  <button type="button" className="btn btn-sm btn-outline-success rounded-pill" onClick={() => startEdit(row)}>
                    ویرایش
                  </button>
                  <button type="button" className="btn btn-sm btn-outline-danger rounded-pill" onClick={() => handleDelete(row)}>
                    حذف
                  </button>
                </div>
              </div>
            </div>
          ))}
          {!rows.length && <div className="empty-state col-12">مدرسی یافت نشد.</div>}
        </div>
      )}
    </div>
  )
}
