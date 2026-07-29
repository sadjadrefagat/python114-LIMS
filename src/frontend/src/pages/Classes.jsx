import { useEffect, useState } from 'react'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker from '../components/JalaliDatePicker'

const statusMap = {
  draft: 'پیش‌نویس',
  open: 'باز',
  full: 'تکمیل ظرفیت',
  in_progress: 'در حال برگزاری',
  finished: 'پایان‌یافته',
  cancelled: 'لغو شده',
}

export default function Classes() {
  const { hasRole } = useAuth()
  const canCreate = hasRole('admin', 'secretary')
  const [rows, setRows] = useState([])
  const [courses, setCourses] = useState([])
  const [teachers, setTeachers] = useState([])
  const [sessionTypes, setSessionTypes] = useState([])
  const [branches, setBranches] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [form, setForm] = useState({
    course_ref: '',
    teacher_ref: '',
    session_type_ref: '',
    start_date: '',
    end_date: '',
    capacity: '15',
    status: 'open',
    class_type: 'group',
    branch_ref: '',
    location_address: '',
    meeting_link: '',
  })

  async function load() {
    setLoading(true)
    try {
      const [cl, co, te, st, br] = await Promise.all([
        api.get('/classes'),
        api.get('/courses'),
        api.get('/teachers'),
        api.get('/session-types'),
        api.get('/branches'),
      ])
      setRows(cl.classes || [])
      setCourses(co.courses || [])
      setTeachers(te.teachers || [])
      setSessionTypes(st.session_types || [])
      setBranches(br.branches || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  async function handleCreate(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      await api.post('/classes', {
        course_ref: Number(form.course_ref),
        teacher_ref: Number(form.teacher_ref),
        session_type_ref: Number(form.session_type_ref),
        start_date: form.start_date || null,
        end_date: form.end_date || null,
        capacity: Number(form.capacity),
        status: form.status,
        class_type: form.class_type,
        branch_ref: form.branch_ref ? Number(form.branch_ref) : null,
        location_address: form.location_address || null,
        meeting_link: form.meeting_link || null,
      })
      setMessage('کلاس ثبت شد')
      setShowCreate(false)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head d-flex justify-content-between flex-wrap gap-2">
        <div>
          <h1 className="section-title h3 mb-1">کلاس‌ها</h1>
          <p className="muted mb-0">گروه‌های اجرایی وابسته به دوره‌ها</p>
        </div>
        {canCreate && (
          <button className="btn btn-brand rounded-pill" onClick={() => setShowCreate((v) => !v)}>
            {showCreate ? 'بستن' : 'کلاس جدید'}
          </button>
        )}
      </div>

      {showCreate && (
        <div className="create-panel">
          <form className="row g-2" onSubmit={handleCreate}>
            <div className="col-md-4">
              <label className="form-label">دوره</label>
              <VazirSelect required value={form.course_ref} onChange={(v) => setForm((p) => ({ ...p, course_ref: v }))} options={courses.map((c) => ({ value: String(c.Id), label: c.Name }))} />
            </div>
            <div className="col-md-4">
              <label className="form-label">مدرس</label>
              <VazirSelect required value={form.teacher_ref} onChange={(v) => setForm((p) => ({ ...p, teacher_ref: v }))} options={teachers.map((t) => ({ value: String(t.Id), label: `${t.FirstName} ${t.LastName}` }))} />
            </div>
            <div className="col-md-4">
              <label className="form-label">نوع برگزاری</label>
              <VazirSelect required value={form.session_type_ref} onChange={(v) => setForm((p) => ({ ...p, session_type_ref: v }))} options={sessionTypes.map((s) => ({ value: String(s.Id), label: s.Name }))} />
            </div>
            <div className="col-md-3">
              <label className="form-label">شروع</label>
              <JalaliDatePicker value={form.start_date} onChange={(v) => setForm((p) => ({ ...p, start_date: v }))} />
            </div>
            <div className="col-md-3">
              <label className="form-label">پایان</label>
              <JalaliDatePicker value={form.end_date} onChange={(v) => setForm((p) => ({ ...p, end_date: v }))} />
            </div>
            <div className="col-md-2">
              <label className="form-label">ظرفیت</label>
              <input type="number" className="form-control" min={0} value={form.capacity} onChange={(e) => setForm((p) => ({ ...p, capacity: e.target.value }))} required />
            </div>
            <div className="col-md-2">
              <label className="form-label">نوع کلاس</label>
              <VazirSelect value={form.class_type} onChange={(v) => setForm((p) => ({ ...p, class_type: v }))} options={[{ value: 'group', label: 'گروهی' }, { value: 'semi_private', label: 'نیمه‌خصوصی' }, { value: 'private', label: 'خصوصی' }, { value: 'vip', label: 'VIP' }]} />
            </div>
            <div className="col-md-2">
              <label className="form-label">شعبه</label>
              <VazirSelect value={form.branch_ref} onChange={(v) => setForm((p) => ({ ...p, branch_ref: v }))} placeholder="اختیاری" options={branches.map((b) => ({ value: String(b.Id), label: b.Name }))} />
            </div>
            <div className="col-md-6">
              <label className="form-label">آدرس حضوری</label>
              <input className="form-control" value={form.location_address} onChange={(e) => setForm((p) => ({ ...p, location_address: e.target.value }))} />
            </div>
            <div className="col-md-6">
              <label className="form-label">لینک آنلاین</label>
              <input className="form-control" value={form.meeting_link} onChange={(e) => setForm((p) => ({ ...p, meeting_link: e.target.value }))} />
            </div>
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>{busy ? '...' : 'ثبت کلاس'}</button>
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
                <th>کد</th>
                <th>دوره</th>
                <th>مدرس</th>
                <th>نوع جلسه</th>
                <th>ظرفیت</th>
                <th>ثبت‌نام</th>
                <th>وضعیت</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.CourseName}</td>
                  <td>{row.TeacherName}</td>
                  <td>{row.SessionTypeName}</td>
                  <td>{row.Capacity}</td>
                  <td>{row.EnrolledCount}</td>
                  <td>
                    <span className="chip chip-teal">{statusMap[row.Status] || row.Status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">کلاسی یافت نشد.</div>}
        </div>
      )}
    </div>
  )
}
