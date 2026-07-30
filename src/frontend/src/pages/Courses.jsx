import { useEffect, useState } from 'react'
import { api, formatMoney } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'
import CourseCard from '../components/CourseCard'
const TEACHING_METHODS = [
  { value: 'حضوری', label: 'حضوری' },
  { value: 'آنلاین', label: 'آنلاین' },
  { value: 'ترکیبی', label: 'ترکیبی (حضوری و آنلاین)' },
  { value: 'مکالمه‌محور', label: 'مکالمه‌محور' },
  { value: 'گرامرمحور', label: 'گرامرمحور' },
  { value: 'مهارت‌محور', label: 'مهارت‌محور' },
  { value: 'آزمون‌محور', label: 'آزمون‌محور' },
  { value: 'فشرده', label: 'فشرده' },
]

const AGE_GROUPS = [
  { value: 'کودک', label: 'کودک' },
  { value: 'نوجوان', label: 'نوجوان' },
  { value: 'جوان', label: 'جوان' },
  { value: 'بزرگسال', label: 'بزرگسال' },
  { value: 'همه سنین', label: 'همه سنین' },
]

const emptyForm = {
  name: '',
  language_ref: '',
  level_ref: '',
  sessions_count: '20',
  cost: '',
  description: '',
  teaching_method: '',
  age_group: '',
  is_highlighted: '0',
}

export default function Courses() {
  const { hasRole } = useAuth()
  const canCreate = hasRole('admin', 'secretary', 'education')
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [courses, setCourses] = useState([])
  const [languages, setLanguages] = useState([])
  const [levels, setLevels] = useState([])
  const [search, setSearch] = useState('')
  const [languageRef, setLanguageRef] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const paging = useClientPagination(courses)

  useEffect(() => {
    api.get('/languages').then((d) => setLanguages(d.languages || [])).catch(() => {})
  }, [])

  useEffect(() => {
    if (!form.language_ref) {
      setLevels([])
      return
    }
    api
      .get(`/levels?language_ref=${form.language_ref}`)
      .then((d) => setLevels(d.levels || []))
      .catch(() => setLevels([]))
  }, [form.language_ref])

  useEffect(() => {
    const timer = setTimeout(async () => {
      setLoading(true)
      setError('')
      try {
        const params = new URLSearchParams()
        if (search.trim()) params.set('search', search.trim())
        if (languageRef) params.set('language_ref', languageRef)
        const q = params.toString()
        const data = await api.get(`/courses${q ? `?${q}` : ''}`)
        setCourses(data.courses || [])
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }, 250)
    return () => clearTimeout(timer)
  }, [search, languageRef])

  function resetForm() {
    setEditId(null)
    setForm(emptyForm)
    setShowCreate(false)
  }

  function startEdit(course) {
    setEditId(course.Id)
    setForm({
      name: course.Name || '',
      language_ref: String(course.LanguageRef || ''),
      level_ref: course.LevelRef ? String(course.LevelRef) : '',
      sessions_count: String(course.SessionsCount ?? '20'),
      cost: String(course.Cost ?? ''),
      description: course.Description || '',
      teaching_method: course.TeachingMethod || '',
      age_group: course.AgeGroup || '',
      is_highlighted: course.IsHighlighted ? '1' : '0',
    })
    setShowCreate(true)
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function reloadList() {
    const params = new URLSearchParams()
    if (search.trim()) params.set('search', search.trim())
    if (languageRef) params.set('language_ref', languageRef)
    const q = params.toString()
    const data = await api.get(`/courses${q ? `?${q}` : ''}`)
    setCourses(data.courses || [])
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const payload = {
        name: form.name.trim(),
        language_ref: Number(form.language_ref),
        level_ref: form.level_ref ? Number(form.level_ref) : null,
        sessions_count: Number(form.sessions_count),
        cost: Number(form.cost),
        description: form.description.trim(),
        teaching_method: form.teaching_method,
        age_group: form.age_group,
        is_highlighted: form.is_highlighted === '1',
      }
      if (editId) {
        await api.put(`/courses/${editId}`, payload)
        setMessage('دوره ویرایش شد')
      } else {
        await api.post('/courses', payload)
        setMessage('دوره ثبت شد')
      }
      resetForm()
      await reloadList()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(course) {
    const ok = await askConfirm({
      title: 'حذف دوره',
      message: 'این دوره آرشیو می‌شود و از کاتالوگ فعال خارج خواهد شد.',
      confirmLabel: 'آرشیو دوره',
      details: [
        { label: 'نام دوره', value: course.Name },
        { label: 'زبان', value: course.LanguageName },
        { label: 'سطح', value: course.LevelName },
        { label: 'جلسات', value: course.SessionsCount != null ? `${course.SessionsCount} جلسه` : null },
        { label: 'گروه سنی', value: course.AgeGroup },
        { label: 'شیوه آموزش', value: course.TeachingMethod },
        { label: 'هزینه', value: course.Cost != null ? formatMoney(course.Cost) : null },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/courses/${course.Id}`)
      setMessage('دوره آرشیو شد')
      if (editId === course.Id) resetForm()
      await reloadList()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex flex-wrap justify-content-between align-items-end gap-3">
        <div>
          <h1 className="section-title h3 mb-1">کاتالوگ دوره‌ها</h1>
          <p className="muted mb-0">جستجو و ثبت دوره</p>
        </div>
        {canCreate && (
          <button
            className="btn btn-brand rounded-pill"
            onClick={() => (showCreate ? resetForm() : setShowCreate(true))}
          >
            {showCreate ? 'بستن فرم' : 'ثبت دوره جدید'}
          </button>
        )}
      </div>

      {canCreate && showCreate && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش دوره #${editId}` : 'ثبت دوره جدید'}
            </h2>
            {editId && (
              <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
                انصراف
              </button>
            )}
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-6">
              <label className="form-label">نام دوره</label>
              <input
                className="form-control"
                value={form.name}
                onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
                required
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">زبان</label>
              <VazirSelect
                required
                value={form.language_ref}
                onChange={(v) => setForm((p) => ({ ...p, language_ref: v, level_ref: '' }))}
                options={languages.map((l) => ({ value: String(l.Id), label: l.Name }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">سطح</label>
              <VazirSelect
                value={form.level_ref}
                onChange={(v) => setForm((p) => ({ ...p, level_ref: v }))}
                placeholder="اختیاری"
                options={levels.map((l) => ({
                  value: String(l.Id),
                  label: `${l.Code} — ${l.Name}`,
                }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">تعداد جلسات</label>
              <input
                type="number"
                className="form-control"
                value={form.sessions_count}
                onChange={(e) => setForm((p) => ({ ...p, sessions_count: e.target.value }))}
                min={1}
                required
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">شهریه (ریال)</label>
              <input
                type="number"
                className="form-control"
                value={form.cost}
                onChange={(e) => setForm((p) => ({ ...p, cost: e.target.value }))}
                min={0}
                required
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">روش تدریس</label>
              <VazirSelect
                required
                value={form.teaching_method}
                onChange={(v) => setForm((p) => ({ ...p, teaching_method: v }))}
                placeholder="انتخاب کنید"
                options={TEACHING_METHODS}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">رده سنی</label>
              <VazirSelect
                required
                value={form.age_group}
                onChange={(v) => setForm((p) => ({ ...p, age_group: v }))}
                placeholder="انتخاب کنید"
                options={AGE_GROUPS}
              />
            </div>
            <div className="col-md-9">
              <label className="form-label">توضیحات (حداقل ۱۰ کاراکتر)</label>
              <input
                className="form-control"
                value={form.description}
                onChange={(e) => setForm((p) => ({ ...p, description: e.target.value }))}
                minLength={10}
                required
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">پیشنهادی؟</label>
              <VazirSelect
                value={form.is_highlighted}
                onChange={(v) => setForm((p) => ({ ...p, is_highlighted: v }))}
                options={[
                  { value: '0', label: 'خیر' },
                  { value: '1', label: 'بله' },
                ]}
              />
            </div>
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره' : 'ثبت دوره'}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="panel p-3 mb-4">
        <div className="row g-2">
          <div className="col-md-7">
            <input
              className="form-control"
              placeholder="جستجوی نام دوره..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <div className="col-md-5">
            <VazirSelect
              value={languageRef}
              onChange={setLanguageRef}
              placeholder="همه زبان‌ها"
              options={[
                { value: '', label: 'همه زبان‌ها' },
                ...languages.map((lang) => ({ value: String(lang.Id), label: lang.Name })),
              ]}
            />
          </div>
        </div>
      </div>

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="row g-4">
          {paging.slice.map((course) => (
            <div className="col-md-6 col-xl-4" key={course.Id}>
              <CourseCard
                course={course}
                canManage={canCreate}
                onEdit={startEdit}
                onDelete={handleDelete}
              />
            </div>
          ))}
          {!courses.length && <div className="empty-state col-12">دوره‌ای یافت نشد.</div>}
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
