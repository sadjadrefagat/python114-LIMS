import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, formatMoney } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'

export default function Courses() {
  const { hasRole } = useAuth()
  const canCreate = hasRole('admin', 'secretary')
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
  const [form, setForm] = useState({
    name: '',
    language_ref: '',
    level_ref: '',
    sessions_count: '20',
    cost: '',
    description: '',
    teaching_method: '',
    age_group: '',
    is_highlighted: '0',
  })

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

  async function handleCreate(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      await api.post('/courses', {
        name: form.name.trim(),
        language_ref: Number(form.language_ref),
        level_ref: form.level_ref ? Number(form.level_ref) : null,
        sessions_count: Number(form.sessions_count),
        cost: Number(form.cost),
        description: form.description.trim(),
        teaching_method: form.teaching_method || null,
        age_group: form.age_group || null,
        is_highlighted: form.is_highlighted === '1',
      })
      setMessage('دوره ثبت شد')
      setShowCreate(false)
      setForm({
        name: '',
        language_ref: '',
        level_ref: '',
        sessions_count: '20',
        cost: '',
        description: '',
        teaching_method: '',
        age_group: '',
        is_highlighted: '0',
      })
      const data = await api.get('/courses')
      setCourses(data.courses || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between align-items-end gap-3">
        <div>
          <h1 className="section-title h3 mb-1">کاتالوگ دوره‌ها</h1>
          <p className="muted mb-0">جستجو و ثبت دوره</p>
        </div>
        <button className="btn btn-brand rounded-pill" onClick={() => setShowCreate((v) => !v)}>
          {showCreate ? 'بستن فرم' : 'ثبت دوره جدید'}
        </button>
      </div>

      {showCreate && (
        <div className="create-panel">
          <form className="row g-2" onSubmit={handleCreate}>
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
              <input
                className="form-control"
                value={form.teaching_method}
                onChange={(e) => setForm((p) => ({ ...p, teaching_method: e.target.value }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">رده سنی</label>
              <input
                className="form-control"
                value={form.age_group}
                onChange={(e) => setForm((p) => ({ ...p, age_group: e.target.value }))}
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
                {busy ? '...' : 'ثبت دوره'}
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
        <div className="row g-3">
          {courses.map((course) => (
            <div className="col-md-6 col-lg-4" key={course.Id}>
              <div className="course-tile">
                <div className="d-flex justify-content-between mb-2">
                  <span className="chip chip-teal">{course.LanguageName}</span>
                  {course.LevelName && <span className="chip chip-sky">{course.LevelName}</span>}
                </div>
                <h2 className="h5 fw-bold">{course.Name}</h2>
                <p className="muted small">
                  {course.SessionsCount} جلسه
                  {course.AgeGroup ? ` · ${course.AgeGroup}` : ''}
                </p>
                <div className="d-flex justify-content-between align-items-center mt-3">
                  <strong className="text-success">{formatMoney(course.Cost)}</strong>
                  <Link to={`/courses/${course.Id}`} className="btn btn-sm btn-brand rounded-pill">
                    جزئیات
                  </Link>
                </div>
              </div>
            </div>
          ))}
          {!courses.length && <div className="empty-state col-12">دوره‌ای یافت نشد.</div>}
        </div>
      )}
    </div>
  )
}
