import { useEffect, useMemo, useRef, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, { todayJalaliString } from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'
import { isValidMobile, MOBILE_ERROR, MOBILE_HINT, normalizeMobileInput } from '../utils/mobile'

/** آواتار ناشناس — data URI تا وابسته به فایل خراب/۴۰۴ نباشد */
const ANON_AVATAR =
  'data:image/svg+xml,' +
  encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="anonymous">
      <circle cx="64" cy="64" r="64" fill="#d7ebe6"/>
      <circle cx="64" cy="48" r="26" fill="#8aabb0"/>
      <path fill="#8aabb0" d="M22 114c10-26 28-38 42-38s32 12 42 38"/>
      <circle cx="64" cy="64" r="61" fill="none" stroke="#0f9d8a" stroke-opacity="0.3" stroke-width="3"/>
    </svg>`,
  )

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

function hasPhotoFlag(row) {
  const v = row?.HasPhoto ?? row?.hasPhoto
  return v === true || v === 1 || v === '1'
}

function teacherPhotoUrl(teacherId, version = 0) {
  const q = version ? `?v=${version}` : ''
  return `/api/teachers/${teacherId}/photo${q}`
}

export default function Teachers() {
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [photoFile, setPhotoFile] = useState(null)
  const [photoPreview, setPhotoPreview] = useState(ANON_AVATAR)
  const [removePhoto, setRemovePhoto] = useState(false)
  const [photoVersion, setPhotoVersion] = useState(0)
  const failedPhotosRef = useRef(new Set())
  const isFirstLoad = useRef(true)
  const today = useMemo(() => todayJalaliString(), [])
  const [form, setForm] = useState(emptyForm)
  const paging = useClientPagination(rows)

  function avatarSrc(row) {
    if (!row || !hasPhotoFlag(row) || failedPhotosRef.current.has(row.Id)) return ANON_AVATAR
    return teacherPhotoUrl(row.Id, photoVersion)
  }

  async function load(q = search) {
    if (isFirstLoad.current) setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const data = await api.get(`/teachers${query}`)
      setRows(data.teachers || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
      isFirstLoad.current = false
    }
  }

  useEffect(() => {
    const t = setTimeout(() => load(search), 250)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  useEffect(() => {
    return () => {
      if (photoPreview?.startsWith('blob:')) URL.revokeObjectURL(photoPreview)
    }
  }, [photoPreview])

  function resetForm() {
    setEditId(null)
    setForm(emptyForm)
    setShowCreate(false)
    setPhotoFile(null)
    setRemovePhoto(false)
    if (photoPreview?.startsWith('blob:')) URL.revokeObjectURL(photoPreview)
    setPhotoPreview(ANON_AVATAR)
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
    setPhotoFile(null)
    setRemovePhoto(false)
    if (photoPreview?.startsWith('blob:')) URL.revokeObjectURL(photoPreview)
    setPhotoPreview(avatarSrc(row))
    setShowCreate(true)
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  function onPhotoChange(e) {
    const file = e.target.files?.[0] || null
    if (!file) return
    if (!file.type.startsWith('image/')) {
      setError('فقط فایل تصویری مجاز است')
      return
    }
    if (file.size > 2 * 1024 * 1024) {
      setError('حجم تصویر نباید بیشتر از ۲ مگابایت باشد')
      return
    }
    setError('')
    setRemovePhoto(false)
    setPhotoFile(file)
    if (photoPreview?.startsWith('blob:')) URL.revokeObjectURL(photoPreview)
    setPhotoPreview(URL.createObjectURL(file))
  }

  function clearSelectedPhoto() {
    setPhotoFile(null)
    if (photoPreview?.startsWith('blob:')) URL.revokeObjectURL(photoPreview)
    if (editId && !removePhoto) {
      const row = rows.find((r) => r.Id === editId)
      setPhotoPreview(row ? avatarSrc(row) : ANON_AVATAR)
      return
    }
    setPhotoPreview(ANON_AVATAR)
  }

  function markRemovePhoto() {
    setPhotoFile(null)
    setRemovePhoto(true)
    if (photoPreview?.startsWith('blob:')) URL.revokeObjectURL(photoPreview)
    setPhotoPreview(ANON_AVATAR)
  }

  async function syncPhoto(teacherId) {
    if (removePhoto && editId) {
      await api.delete(`/teachers/${teacherId}/photo`)
      failedPhotosRef.current.add(teacherId)
      return
    }
    if (!photoFile) return
    const fd = new FormData()
    fd.append('photo', photoFile)
    await api.upload(`/teachers/${teacherId}/photo`, fd)
    failedPhotosRef.current.delete(teacherId)
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
        await syncPhoto(editId)
        setMessage('مدرس ویرایش شد')
      } else {
        const created = await api.post('/teachers', payload)
        await syncPhoto(created.id)
        setMessage('مدرس ثبت شد')
      }
      setPhotoVersion((v) => v + 1)
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
      title: 'حذف مدرس',
      message: 'این مدرس آرشیو می‌شود و از فهرست فعال خارج خواهد شد.',
      confirmLabel: 'آرشیو مدرس',
      details: [
        { label: 'نام', value: `${row.FirstName || ''} ${row.LastName || ''}`.trim() },
        { label: 'تخصص', value: row.Specialty },
        { label: 'موبایل', value: row.Mobile },
        { label: 'ایمیل', value: row.Email },
      ],
    })
    if (!ok) return
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
      {confirmDialog}
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
            <div className="col-12">
              <div className="teacher-photo-field">
                <img className="teacher-avatar is-form" src={photoPreview} alt="پیش‌نمایش عکس مدرس" />
                <div className="teacher-photo-controls">
                  <label className="btn btn-sm btn-outline-success rounded-pill mb-0">
                    انتخاب عکس
                    <input
                      type="file"
                      accept="image/jpeg,image/png,image/webp,image/gif"
                      hidden
                      onChange={onPhotoChange}
                    />
                  </label>
                  {photoFile ? (
                    <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={clearSelectedPhoto}>
                      بازنشانی
                    </button>
                  ) : null}
                  {editId && hasPhotoFlag(rows.find((r) => r.Id === editId)) && !removePhoto && (
                    <button type="button" className="btn btn-sm btn-outline-danger rounded-pill" onClick={markRemovePhoto}>
                      حذف عکس
                    </button>
                  )}
                  <div className="form-text mb-0">jpeg / png / webp — حداکثر ۲ مگابایت</div>
                </div>
              </div>
            </div>
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
        <div className="row g-3 grid-zebra">
          {paging.slice.map((row) => (
            <div className="col-md-6 col-lg-4" key={row.Id}>
              <div className="course-tile teacher-card">
                <div className="teacher-card-head">
                  <img
                    className="teacher-avatar"
                    src={avatarSrc(row)}
                    alt={`${row.FirstName || ''} ${row.LastName || ''}`.trim() || 'مدرس'}
                    loading="lazy"
                    decoding="async"
                    onError={() => {
                      if (!failedPhotosRef.current.has(row.Id)) {
                        failedPhotosRef.current.add(row.Id)
                        setPhotoVersion((v) => v + 1)
                      }
                    }}
                  />
                  <div>
                    <h2 className="h5 fw-bold mb-1">
                      {row.FirstName} {row.LastName}
                    </h2>
                    <p className="muted small mb-0">{row.Specialty || 'تخصص ثبت نشده'}</p>
                  </div>
                </div>
                <div className="d-flex flex-wrap gap-2 mb-3">
                  {row.Mobile && <span className="chip chip-sky">{row.Mobile}</span>}
                  <span className="chip chip-teal">{row.Gender === 1 ? 'خانم' : 'آقا'}</span>
                </div>
                <RowActions onEdit={() => startEdit(row)} onDelete={() => handleDelete(row)} />
              </div>
            </div>
          ))}
          {!rows.length && <div className="empty-state col-12">مدرسی یافت نشد.</div>}
          <div className="col-12">
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
        </div>
      )}
    </div>
  )
}
