import { useEffect, useState } from 'react'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, { compareJalali, todayJalaliString } from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import ClassDetailModal from '../components/ClassDetailModal'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const statusMap = {
  draft: 'پیش‌نویس',
  open: 'باز',
  full: 'تکمیل ظرفیت',
  in_progress: 'در حال برگزاری',
  finished: 'پایان‌یافته',
  cancelled: 'لغو شده',
}

const emptyForm = {
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
  cancel_reason: '',
}

export default function Classes() {
  const { hasRole } = useAuth()
  const canCreate = hasRole('admin', 'secretary', 'education')
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [courses, setCourses] = useState([])
  const [teachers, setTeachers] = useState([])
  const [sessionTypes, setSessionTypes] = useState([])
  const [branches, setBranches] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const [viewClassId, setViewClassId] = useState(null)
  const today = todayJalaliString()
  const paging = useClientPagination(rows)

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const [cl, co, te, st, br] = await Promise.all([
        api.get(`/classes${query}`),
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
    const t = setTimeout(() => load(search), 250)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  function changeStartDate(v) {
    setForm((p) => {
      const next = { ...p, start_date: v }
      if (v && p.end_date && compareJalali(p.end_date, v) < 0) {
        next.end_date = ''
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
      course_ref: String(row.CourseRef || ''),
      teacher_ref: String(row.TeacherRef || ''),
      session_type_ref: String(row.SessionTypeRef || ''),
      start_date: row.StartDate || '',
      end_date: row.EndDate || '',
      capacity: String(row.Capacity ?? '15'),
      status: row.Status || 'open',
      class_type: row.ClassType || 'group',
      branch_ref: row.BranchRef ? String(row.BranchRef) : '',
      location_address: row.LocationAddress || '',
      meeting_link: row.MeetingLink || '',
      cancel_reason: row.CancelReason || '',
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

    if (!form.start_date || !form.end_date) {
      setError('تاریخ شروع و پایان کلاس الزامی است')
      setBusy(false)
      return
    }
    if (compareJalali(form.end_date, form.start_date) < 0) {
      setError('تاریخ پایان نباید قبل از تاریخ شروع باشد')
      setBusy(false)
      return
    }
    if (!editId && compareJalali(form.start_date, today) < 0) {
      setError('ثبت کلاس با تاریخ گذشته مجاز نیست')
      setBusy(false)
      return
    }
    if (form.status === 'cancelled' && !form.cancel_reason.trim()) {
      setError('برای لغو کلاس، دلیل الزامی است')
      setBusy(false)
      return
    }

    try {
      if (editId) {
        await api.put(`/classes/${editId}`, {
          teacher_ref: Number(form.teacher_ref),
          session_type_ref: Number(form.session_type_ref),
          start_date: form.start_date,
          end_date: form.end_date,
          capacity: Number(form.capacity),
          status: form.status,
          cancel_reason: form.status === 'cancelled' ? form.cancel_reason.trim() : null,
          class_type: form.class_type,
          branch_ref: form.branch_ref ? Number(form.branch_ref) : null,
          location_address: form.location_address || null,
          meeting_link: form.meeting_link || null,
        })
        setMessage('کلاس ویرایش شد')
      } else {
        await api.post('/classes', {
          course_ref: Number(form.course_ref),
          teacher_ref: Number(form.teacher_ref),
          session_type_ref: Number(form.session_type_ref),
          start_date: form.start_date,
          end_date: form.end_date,
          capacity: Number(form.capacity),
          status: form.status,
          class_type: form.class_type,
          branch_ref: form.branch_ref ? Number(form.branch_ref) : null,
          location_address: form.location_address || null,
          meeting_link: form.meeting_link || null,
        })
        setMessage('کلاس ثبت شد')
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
      title: 'لغو کلاس',
      message: 'این کلاس لغو می‌شود و از فهرست کلاس‌های فعال خارج خواهد شد.',
      confirmLabel: 'لغو کلاس',
      details: [
        { label: 'شناسه', value: `#${row.Id}` },
        { label: 'دوره', value: row.CourseName },
        { label: 'مدرس', value: row.TeacherName },
        { label: 'شروع', value: row.StartDate },
        { label: 'ظرفیت', value: row.Capacity },
        { label: 'وضعیت', value: statusMap[row.Status] || row.Status },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/classes/${row.Id}`)
      setMessage('کلاس لغو شد')
      if (editId === row.Id) resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex justify-content-between flex-wrap gap-2">
        <div>
          <h1 className="section-title h3 mb-1">کلاس‌ها</h1>
          <p className="muted mb-0">گروه‌های اجرایی وابسته به دوره‌ها</p>
        </div>
        <div className="d-flex gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 220 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          {canCreate && (
            <button
              className="btn btn-brand rounded-pill"
              onClick={() => (showCreate ? resetForm() : setShowCreate(true))}
            >
              {showCreate ? 'بستن' : 'کلاس جدید'}
            </button>
          )}
        </div>
      </div>

      {showCreate && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش کلاس #${editId}` : 'ثبت کلاس جدید'}
            </h2>
            {editId && (
              <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
                انصراف
              </button>
            )}
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">دوره</label>
              <VazirSelect
                required
                disabled={Boolean(editId)}
                value={form.course_ref}
                onChange={(v) => setForm((p) => ({ ...p, course_ref: v }))}
                options={courses.map((c) => ({ value: String(c.Id), label: c.Name }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">مدرس</label>
              <VazirSelect
                required
                value={form.teacher_ref}
                onChange={(v) => setForm((p) => ({ ...p, teacher_ref: v }))}
                options={teachers.map((t) => ({
                  value: String(t.Id),
                  label: `${t.FirstName} ${t.LastName}`,
                }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">نوع برگزاری</label>
              <VazirSelect
                required
                value={form.session_type_ref}
                onChange={(v) => setForm((p) => ({ ...p, session_type_ref: v }))}
                options={sessionTypes.map((s) => ({ value: String(s.Id), label: s.Name }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">تاریخ شروع</label>
              <JalaliDatePicker
                required
                value={form.start_date}
                onChange={changeStartDate}
                minDate={editId ? '' : today}
                maxDate={form.end_date || ''}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">تاریخ پایان</label>
              <JalaliDatePicker
                required
                value={form.end_date}
                onChange={(v) => setForm((p) => ({ ...p, end_date: v }))}
                minDate={form.start_date || (editId ? '' : today)}
              />
            </div>
            <div className="col-md-2">
              <label className="form-label">ظرفیت</label>
              <input
                type="number"
                className="form-control"
                min={0}
                value={form.capacity}
                onChange={(e) => setForm((p) => ({ ...p, capacity: e.target.value }))}
                required
              />
            </div>
            <div className="col-md-2">
              <label className="form-label">نوع کلاس</label>
              <VazirSelect
                value={form.class_type}
                onChange={(v) => setForm((p) => ({ ...p, class_type: v }))}
                options={[
                  { value: 'group', label: 'گروهی' },
                  { value: 'semi_private', label: 'نیمه‌خصوصی' },
                  { value: 'private', label: 'خصوصی' },
                  { value: 'vip', label: 'VIP' },
                ]}
              />
            </div>
            {editId && (
              <div className="col-md-2">
                <label className="form-label">وضعیت</label>
                <VazirSelect
                  value={form.status}
                  onChange={(v) => setForm((p) => ({ ...p, status: v }))}
                  options={Object.entries(statusMap).map(([value, label]) => ({ value, label }))}
                />
              </div>
            )}
            <div className="col-md-2">
              <label className="form-label">شعبه</label>
              <VazirSelect
                value={form.branch_ref}
                onChange={(v) => setForm((p) => ({ ...p, branch_ref: v }))}
                placeholder="اختیاری"
                options={branches.map((b) => ({ value: String(b.Id), label: b.Name }))}
              />
            </div>
            <div className="col-md-6">
              <label className="form-label">آدرس حضوری</label>
              <input
                className="form-control"
                value={form.location_address}
                onChange={(e) => setForm((p) => ({ ...p, location_address: e.target.value }))}
              />
            </div>
            <div className="col-md-6">
              <label className="form-label">لینک آنلاین</label>
              <input
                className="form-control"
                value={form.meeting_link}
                onChange={(e) => setForm((p) => ({ ...p, meeting_link: e.target.value }))}
              />
            </div>
            {editId && form.status === 'cancelled' && (
              <div className="col-md-6">
                <label className="form-label">دلیل لغو</label>
                <input
                  className="form-control"
                  value={form.cancel_reason}
                  onChange={(e) => setForm((p) => ({ ...p, cancel_reason: e.target.value }))}
                  required
                />
              </div>
            )}
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره تغییرات' : 'ثبت کلاس'}
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
                <th>کد</th>
                <th>دوره</th>
                <th>مدرس</th>
                <th>نوع جلسه</th>
                <th>ظرفیت</th>
                <th>ثبت‌نام</th>
                <th>وضعیت</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
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
                  <td className="text-nowrap">
                    <RowActions
                      onView={() => setViewClassId(row.Id)}
                      onEdit={canCreate ? () => startEdit(row) : undefined}
                      onDelete={canCreate ? () => handleDelete(row) : undefined}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">کلاسی یافت نشد.</div>}
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

      <ClassDetailModal
        open={viewClassId != null}
        classId={viewClassId}
        onClose={() => setViewClassId(null)}
      />
    </div>
  )
}
