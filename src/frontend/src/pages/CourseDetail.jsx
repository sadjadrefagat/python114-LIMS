import { useEffect, useMemo, useState } from 'react'
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom'
import { api, formatMoney } from '../api/client'
import { useAuth } from '../context/AuthContext'
import { todayJalaliString } from '../components/JalaliDatePicker'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'

const statusLabel = {
  draft: 'پیش‌نویس',
  open: 'باز برای ثبت‌نام',
  full: 'تکمیل ظرفیت',
  in_progress: 'در حال برگزاری',
  finished: 'پایان‌یافته',
  cancelled: 'لغو شده',
}

export default function CourseDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const { user, isAuthenticated, loading: authLoading, hasRole } = useAuth()
  const isStaff = hasRole('admin', 'secretary', 'education')

  const [course, setCourse] = useState(null)
  const [classes, setClasses] = useState([])
  const [students, setStudents] = useState([])
  const [selectedClass, setSelectedClass] = useState('')
  const [selectedStudent, setSelectedStudent] = useState('')
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const paging = useClientPagination(classes)

  useEffect(() => {
    setLoading(true)
    Promise.all([api.get(`/courses/${id}`), api.get(`/classes?course_ref=${id}`)])
      .then(([courseData, classData]) => {
        setCourse(courseData.course)
        const list = classData.classes || []
        setClasses(list)
        const openOne = list.find((c) => c.Status === 'open' || c.Status === 'in_progress')
        setSelectedClass(openOne ? String(openOne.Id) : list[0] ? String(list[0].Id) : '')
        setError('')
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [id])

  useEffect(() => {
    if (!isStaff) return undefined
    api
      .get('/students')
      .then((d) => setStudents(d.students || []))
      .catch(() => setStudents([]))
    return undefined
  }, [isStaff])

  useEffect(() => {
    if (!course || location.hash !== '#enroll') return
    const el = document.getElementById('enroll')
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }, [course, location.hash])

  const openClasses = useMemo(
    () => classes.filter((c) => ['open', 'in_progress'].includes(c.Status)),
    [classes],
  )

  const classOptions = useMemo(
    () =>
      classes.map((c) => {
        const seats = Math.max(0, (c.Capacity || 0) - (c.EnrolledCount || 0))
        return {
          value: String(c.Id),
          label: `${c.TeacherName || 'مدرس'} · ${c.SessionTypeName || '—'} · ظرفیت باقی‌مانده: ${seats} · ${statusLabel[c.Status] || c.Status}`,
          disabled: !['open', 'in_progress'].includes(c.Status) || seats <= 0,
        }
      }),
    [classes],
  )

  async function handleEnroll(e) {
    e.preventDefault()
    setMessage('')
    setError('')

    if (!isAuthenticated) {
      navigate('/login', { state: { from: `/courses/${id}` } })
      return
    }

    const studentRef = isStaff ? Number(selectedStudent) : user?.student_ref
    if (!studentRef) {
      setError(
        isStaff
          ? 'لطفاً زبان‌آموز را انتخاب کنید'
          : 'حساب شما به پروفایل زبان‌آموز وصل نیست. با حساب زبان‌آموز وارد شوید یا از منشی کمک بگیرید.',
      )
      return
    }

    if (!selectedClass) {
      setError('لطفاً یک کلاس را انتخاب کنید')
      return
    }

    const chosen = classes.find((c) => String(c.Id) === String(selectedClass))
    if (!chosen || !['open', 'in_progress'].includes(chosen.Status)) {
      setError('این کلاس برای ثبت‌نام فعال نیست')
      return
    }

    setBusy(true)
    try {
      await api.post('/enrollments', {
        student_ref: studentRef,
        class_ref: Number(selectedClass),
        course_ref: Number(id),
        date: todayJalaliString(),
        status: 'pending_payment',
        financial_status: 'debtor',
      })
      setMessage(
        isStaff
          ? 'ثبت‌نام زبان‌آموز با موفقیت انجام شد. وضعیت: در انتظار پرداخت'
          : 'ثبت‌نام شما با موفقیت انجام شد. وضعیت: در انتظار پرداخت',
      )
      const refreshed = await api.get(`/classes?course_ref=${id}`)
      setClasses(refreshed.classes || [])
    } catch (err) {
      setError(err.message || 'ثبت‌نام ناموفق بود')
    } finally {
      setBusy(false)
    }
  }

  if (loading || authLoading) return <Loading />
  if (error && !course) {
    return (
      <div className="container py-5">
        <div className="alert alert-danger">{error}</div>
        <Link to="/courses">بازگشت</Link>
      </div>
    )
  }
  if (!course) return null

  return (
    <div className="container py-4">
      <Link to="/courses" className="text-success small">
        ← بازگشت به دوره‌ها
      </Link>

      <div className="panel p-4 mt-3 fade-up">
        <div className="d-flex flex-wrap gap-2 mb-3">
          <span className="chip chip-teal">{course.LanguageName}</span>
          {course.LevelName && <span className="chip chip-sky">{course.LevelName}</span>}
          {course.IsHighlighted ? <span className="chip chip-coral">پیشنهادی</span> : null}
        </div>
        <h1 className="h3 fw-bold section-title">{course.Name}</h1>
        <p className="muted">{course.Description || 'توضیحات تکمیلی برای این دوره ثبت نشده است.'}</p>
        <div className="row g-3 mt-2">
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">شهریه</div>
              <div className="value" style={{ fontSize: '1.15rem' }}>
                {formatMoney(course.Cost)}
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">تعداد جلسات</div>
              <div className="value">{course.SessionsCount}</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">مدت (ساعت)</div>
              <div className="value">{course.DurationHours ?? '—'}</div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">روش تدریس</div>
              <div className="value" style={{ fontSize: '1rem' }}>
                {course.TeachingMethod || '—'}
              </div>
            </div>
          </div>
          <div className="col-md-3">
            <div className="stat-box">
              <div className="small muted">رده سنی</div>
              <div className="value" style={{ fontSize: '1rem' }}>
                {course.AgeGroup || '—'}
              </div>
            </div>
          </div>
        </div>
        {course.Syllabus && (
          <div className="mt-4">
            <h2 className="h6 fw-bold">سرفصل</h2>
            <p className="mb-0" style={{ whiteSpace: 'pre-wrap' }}>
              {course.Syllabus}
            </p>
          </div>
        )}
      </div>

      <div id="enroll" className="create-panel mt-4 fade-up-delay">
        <h2 className="h5 fw-bold section-title mb-1">ثبت‌نام در این دوره</h2>
        <p className="muted small mb-3">
          {isStaff
            ? 'به‌عنوان مدیر/منشی می‌توانید برای هر زبان‌آموز کلاس را انتخاب و ثبت‌نام کنید.'
            : 'یکی از کلاس‌های فعال این دوره را انتخاب کنید و ثبت‌نام را نهایی کنید.'}
        </p>

        {message && <div className="alert alert-success py-2">{message}</div>}
        {error && course && <div className="alert alert-danger py-2">{error}</div>}

        {!classes.length ? (
          <div className="empty-state py-3">هنوز کلاسی برای این دوره تعریف نشده است.</div>
        ) : !openClasses.length ? (
          <div className="alert alert-warning py-2 mb-0">
            در حال حاضر کلاس بازی برای ثبت‌نام وجود ندارد.
          </div>
        ) : (
          <form className="row g-3 align-items-end" onSubmit={handleEnroll}>
            {isStaff && (
              <div className="col-lg-5">
                <label className="form-label">زبان‌آموز</label>
                <VazirSelect
                  required
                  value={selectedStudent}
                  onChange={setSelectedStudent}
                  placeholder="انتخاب زبان‌آموز"
                  options={students.map((s) => ({
                    value: String(s.Id),
                    label: `${s.FirstName} ${s.LastName} · ${s.NationalCode || s.Id}`,
                  }))}
                />
              </div>
            )}
            <div className={isStaff ? 'col-lg-4' : 'col-lg-8'}>
              <label className="form-label">انتخاب کلاس</label>
              <VazirSelect
                required
                value={selectedClass}
                onChange={setSelectedClass}
                placeholder="کلاس را انتخاب کنید"
                options={classOptions.filter((o) => !o.disabled)}
              />
            </div>
            <div className={isStaff ? 'col-lg-3' : 'col-lg-4'} style={{ display: 'grid' }}>
              {!isAuthenticated ? (
                <div className="d-grid gap-2">
                  <Link
                    className="btn btn-brand rounded-pill"
                    to="/login"
                    state={{ from: location.pathname }}
                  >
                    ورود و ثبت‌نام در دوره
                  </Link>
                  <Link
                    className="btn btn-accent rounded-pill"
                    to="/register"
                    state={{ from: location.pathname }}
                  >
                    ساخت حساب و ثبت‌نام
                  </Link>
                </div>
              ) : (
                <button className="btn btn-brand rounded-pill py-2" disabled={busy}>
                  {busy ? 'در حال ثبت‌نام...' : isStaff ? 'ثبت‌نام زبان‌آموز' : 'ثبت‌نام در این دوره'}
                </button>
              )}
            </div>
          </form>
        )}

        {classes.length > 0 && (
          <div className="table-responsive mt-4">
            <table className="table table-zebra align-middle mb-0">
              <thead>
                <tr>
                  <th>کد کلاس</th>
                  <th>مدرس</th>
                  <th>نوع</th>
                  <th>ظرفیت</th>
                  <th>ثبت‌نام‌شده</th>
                  <th>وضعیت</th>
                </tr>
              </thead>
              <tbody>
                {paging.slice.map((c) => (
                  <tr key={c.Id}>
                    <td>{c.Id}</td>
                    <td>{c.TeacherName}</td>
                    <td>{c.SessionTypeName}</td>
                    <td>{c.Capacity}</td>
                    <td>{c.EnrolledCount}</td>
                    <td>
                      <span className="chip chip-teal">{statusLabel[c.Status] || c.Status}</span>
                    </td>
                  </tr>
                ))}
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
    </div>
  )
}
