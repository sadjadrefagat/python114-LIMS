import { useEffect, useState } from 'react'
import { api, roleLabel } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'

const emptyForm = {
  username: '',
  password: '',
  full_name: '',
  email: '',
  role_code: 'secretary',
  teacher_ref: '',
  student_ref: '',
  is_active: '1',
}

const ROLE_HINTS = {
  admin: 'دسترسی کامل به همه بخش‌ها',
  secretary: 'مدیریت آموزش، افراد، ثبت‌نام و تنظیمات',
  education: 'مشابه منشی — مدیریت آموزش و کلاس‌ها',
  finance: 'گزارش‌ها و عملیات مالی',
  teacher: 'جلسات و ثبت حضور و غیاب (نیاز به اتصال پروفایل مدرس)',
  student: 'ثبت‌نام عمومی (نیاز به اتصال پروفایل زبان‌آموز)',
  parent: 'دسترسی والدین (آینده)',
}

export default function Users() {
  const { hasRole } = useAuth()
  const isAdmin = hasRole('admin')
  const [rows, setRows] = useState([])
  const [roles, setRoles] = useState([])
  const [teachers, setTeachers] = useState([])
  const [students, setStudents] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const paging = useClientPagination(rows)

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const [u, r, t, s] = await Promise.all([
        api.get(`/users${query}`),
        api.get('/auth/roles'),
        api.get('/teachers'),
        api.get('/students'),
      ])
      setRows(u.users || [])
      setRoles(r.roles || [])
      setTeachers(t.teachers || [])
      setStudents(s.students || [])
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (!isAdmin) return undefined
    const t = setTimeout(() => load(search), 250)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, isAdmin])

  function resetForm() {
    setEditId(null)
    setForm(emptyForm)
    setShowCreate(false)
  }

  function startEdit(row) {
    setEditId(row.Id)
    setShowCreate(true)
    setForm({
      username: row.Username || '',
      password: '',
      full_name: row.FullName || '',
      email: row.Email || '',
      role_code: row.RoleCode || 'secretary',
      teacher_ref: row.TeacherRef ? String(row.TeacherRef) : '',
      student_ref: row.StudentRef ? String(row.StudentRef) : '',
      is_active: row.IsActive ? '1' : '0',
    })
    setError('')
    setMessage('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const payload = {
        full_name: form.full_name.trim(),
        email: form.email.trim() || null,
        role_code: form.role_code,
        teacher_ref: form.role_code === 'teacher' && form.teacher_ref ? Number(form.teacher_ref) : null,
        student_ref: form.role_code === 'student' && form.student_ref ? Number(form.student_ref) : null,
        is_active: form.is_active === '1',
      }
      if (editId) {
        if (form.password.trim()) payload.password = form.password
        await api.put(`/users/${editId}`, payload)
        setMessage('کاربر به‌روزرسانی شد')
      } else {
        await api.post('/users', {
          ...payload,
          username: form.username.trim(),
          password: form.password,
        })
        setMessage('کاربر ایجاد شد')
      }
      resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  if (!isAdmin) {
    return (
      <div className="container py-4">
        <div className="alert alert-warning">فقط مدیر سیستم به مدیریت کاربران دسترسی دارد.</div>
      </div>
    )
  }

  return (
    <div className="container py-4">
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">کاربران و دسترسی‌ها</h1>
          <p className="muted mb-0">
            تعریف منشی، مسئول آموزش، مدرس و سایر نقش‌ها — دسترسی هر نقش از منوی کنار مشخص می‌شود
          </p>
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
            type="button"
            className="btn btn-brand rounded-pill"
            onClick={() => {
              resetForm()
              setShowCreate(true)
            }}
          >
            کاربر جدید
          </button>
        </div>
      </div>

      {showCreate && (
        <div className="create-panel">
          <div className="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
            <h2 className="h6 fw-bold mb-0">{editId ? `ویرایش کاربر #${editId}` : 'ایجاد کاربر'}</h2>
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
              انصراف
            </button>
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            {!editId && (
              <div className="col-md-4">
                <label className="form-label">نام کاربری</label>
                <input
                  className="form-control"
                  required
                  minLength={3}
                  value={form.username}
                  onChange={(e) => setForm((p) => ({ ...p, username: e.target.value }))}
                />
              </div>
            )}
            <div className="col-md-4">
              <label className="form-label">{editId ? 'رمز جدید (اختیاری)' : 'رمز عبور'}</label>
              <input
                type="password"
                className="form-control"
                required={!editId}
                minLength={8}
                value={form.password}
                onChange={(e) => setForm((p) => ({ ...p, password: e.target.value }))}
                autoComplete="new-password"
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">نام کامل</label>
              <input
                className="form-control"
                required
                value={form.full_name}
                onChange={(e) => setForm((p) => ({ ...p, full_name: e.target.value }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">ایمیل</label>
              <input
                type="email"
                className="form-control"
                value={form.email}
                onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">نقش / دسترسی</label>
              <VazirSelect
                required
                value={form.role_code}
                onChange={(v) => setForm((p) => ({ ...p, role_code: v }))}
                options={roles.map((r) => ({
                  value: r.Code,
                  label: `${r.Name} (${r.Code})`,
                }))}
              />
              <div className="form-text">{ROLE_HINTS[form.role_code] || ''}</div>
            </div>
            <div className="col-md-4">
              <label className="form-label">وضعیت</label>
              <VazirSelect
                value={form.is_active}
                onChange={(v) => setForm((p) => ({ ...p, is_active: v }))}
                options={[
                  { value: '1', label: 'فعال' },
                  { value: '0', label: 'غیرفعال' },
                ]}
              />
            </div>
            {form.role_code === 'teacher' && (
              <div className="col-md-6">
                <label className="form-label">پروفایل مدرس</label>
                <VazirSelect
                  required
                  value={form.teacher_ref}
                  onChange={(v) => setForm((p) => ({ ...p, teacher_ref: v }))}
                  placeholder="اتصال به مدرس"
                  options={teachers.map((t) => ({
                    value: String(t.Id),
                    label: `${t.FirstName} ${t.LastName}`,
                  }))}
                />
              </div>
            )}
            {form.role_code === 'student' && (
              <div className="col-md-6">
                <label className="form-label">پروفایل زبان‌آموز</label>
                <VazirSelect
                  required
                  value={form.student_ref}
                  onChange={(v) => setForm((p) => ({ ...p, student_ref: v }))}
                  placeholder="اتصال به زبان‌آموز"
                  options={students.map((s) => ({
                    value: String(s.Id),
                    label: `${s.FirstName} ${s.LastName}`,
                  }))}
                />
              </div>
            )}
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره تغییرات' : 'ایجاد کاربر'}
              </button>
            </div>
          </form>
        </div>
      )}

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      <div className="panel mb-3 p-3">
        <h2 className="h6 mb-2">راهنمای دسترسی نقش‌ها</h2>
        <ul className="mb-0 small muted" style={{ lineHeight: 1.9 }}>
          <li>
            <strong>منشی / مسئول آموزش:</strong> زبان‌ها، سطح‌ها، دوره‌ها، کلاس‌ها، جلسات، افراد، ثبت‌نام‌ها
          </li>
          <li>
            <strong>مدرس:</strong> فقط جلسات و ثبت حضور و غیاب کلاس‌های خودش
          </li>
          <li>
            <strong>مالی:</strong> گزارش‌های مالی داشبورد
          </li>
          <li>
            <strong>مدیر:</strong> همه موارد + ایجاد و ویرایش کاربران همین صفحه
          </li>
        </ul>
      </div>

      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>نام کاربری</th>
                <th>نام</th>
                <th>نقش</th>
                <th>اتصال</th>
                <th>وضعیت</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.Username}</td>
                  <td>{row.FullName || '—'}</td>
                  <td>
                    <span className="chip chip-teal">{row.RoleName || roleLabel(row.RoleCode)}</span>
                  </td>
                  <td className="small">
                    {row.TeacherName ? `مدرس: ${row.TeacherName}` : null}
                    {row.StudentName ? `زبان‌آموز: ${row.StudentName}` : null}
                    {!row.TeacherName && !row.StudentName ? '—' : null}
                  </td>
                  <td>{row.IsActive ? 'فعال' : 'غیرفعال'}</td>
                  <td className="text-nowrap">
                    <RowActions onEdit={() => startEdit(row)} />
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={7} className="text-center muted py-4">
                    کاربری یافت نشد
                  </td>
                </tr>
              )}
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
  )
}
