import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, roleLabel } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import PasswordResetDialog from '../components/PasswordResetDialog'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

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
  finance: 'فقط ثبت و مشاهده پرداخت‌ها + داشبورد مالی',
  teacher: 'دسترسی پنل مدرس — باید به یک پروفایل مدرس آزاد متصل شود',
  student: 'دسترسی زبان‌آموز — باید به یک پروفایل زبان‌آموز آزاد متصل شود',
  parent: 'دسترسی والدین (آینده)',
}

function profileLabel(p) {
  const name = `${p.FirstName || ''} ${p.LastName || ''}`.trim()
  const bits = [name]
  if (p.NationalCode) bits.push(`کدملی ${p.NationalCode}`)
  if (p.Mobile) bits.push(p.Mobile)
  return bits.join(' · ')
}

export default function Users() {
  const { hasRole } = useAuth()
  const isAdmin = hasRole('admin')
  const [askConfirm, confirmDialog] = useConfirmDialog()
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
  const [linkUnlocked, setLinkUnlocked] = useState(false)
  const [originalTeacherRef, setOriginalTeacherRef] = useState('')
  const [originalStudentRef, setOriginalStudentRef] = useState('')
  const [resetTarget, setResetTarget] = useState(null)
  const [resetBusy, setResetBusy] = useState(false)
  const paging = useClientPagination(rows)

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const [u, r, links] = await Promise.all([
        api.get(`/users${query}`),
        api.get('/auth/roles'),
        api.get('/users/link-options'),
      ])
      setRows(u.users || [])
      setRoles(r.roles || [])
      setTeachers(links.teachers || [])
      setStudents(links.students || [])
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

  const availableTeachers = useMemo(() => {
    return teachers.filter(
      (t) => !t.LinkedUserId || (editId && Number(t.LinkedUserId) === Number(editId)),
    )
  }, [teachers, editId])

  const availableStudents = useMemo(() => {
    return students.filter(
      (s) => !s.LinkedUserId || (editId && Number(s.LinkedUserId) === Number(editId)),
    )
  }, [students, editId])

  const linkedTeacher = useMemo(
    () => teachers.find((t) => String(t.Id) === String(form.teacher_ref)) || null,
    [teachers, form.teacher_ref],
  )
  const linkedStudent = useMemo(
    () => students.find((s) => String(s.Id) === String(form.student_ref)) || null,
    [students, form.student_ref],
  )

  const needsProfile = form.role_code === 'teacher' || form.role_code === 'student'
  const hasExistingLink =
    Boolean(editId) &&
    ((form.role_code === 'teacher' && originalTeacherRef) ||
      (form.role_code === 'student' && originalStudentRef))
  const showLinkPicker = needsProfile && (!hasExistingLink || linkUnlocked)

  function resetForm() {
    setEditId(null)
    setForm(emptyForm)
    setShowCreate(false)
    setLinkUnlocked(false)
    setOriginalTeacherRef('')
    setOriginalStudentRef('')
  }

  function startEdit(row) {
    setEditId(row.Id)
    setShowCreate(true)
    setLinkUnlocked(false)
    const tRef = row.TeacherRef ? String(row.TeacherRef) : ''
    const sRef = row.StudentRef ? String(row.StudentRef) : ''
    setOriginalTeacherRef(tRef)
    setOriginalStudentRef(sRef)
    setForm({
      username: row.Username || '',
      password: '',
      full_name: row.FullName || '',
      email: row.Email || '',
      role_code: row.RoleCode || 'secretary',
      teacher_ref: tRef,
      student_ref: sRef,
      is_active: row.IsActive ? '1' : '0',
    })
    setError('')
    setMessage('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  function onRoleChange(role) {
    setForm((p) => ({
      ...p,
      role_code: role,
      teacher_ref: role === 'teacher' ? (editId ? originalTeacherRef : '') : '',
      student_ref: role === 'student' ? (editId ? originalStudentRef : '') : '',
    }))
    setLinkUnlocked(false)
  }

  async function unlockLinkChange() {
    const ok = await askConfirm({
      title: 'تغییر اتصال پروفایل',
      message:
        'اتصال فعلی قطع می‌شود و باید یک پروفایل آزاد دیگر انتخاب کنید. پروفایل‌هایی که قبلاً به حساب دیگری وصل‌اند در فهرست نمی‌آیند.',
      confirmLabel: 'ادامه',
    })
    if (!ok) return
    setLinkUnlocked(true)
    setForm((p) => ({
      ...p,
      teacher_ref: p.role_code === 'teacher' ? '' : p.teacher_ref,
      student_ref: p.role_code === 'student' ? '' : p.student_ref,
    }))
  }

  async function startResetPassword(row) {
    const ok = await askConfirm({
      title: 'بازنشانی رمز عبور',
      message: 'رمز فعلی این کاربر باطل می‌شود و باید رمز جدید تعیین کنید. جلسات فعال او نیز قطع می‌شوند.',
      details: [
        { label: 'نام', value: row.FullName || '—' },
        { label: 'نام کاربری', value: row.Username },
      ],
      confirmLabel: 'ادامه',
      cancelLabel: 'انصراف',
      tone: 'warn',
    })
    if (!ok) return
    setResetTarget(row)
    setError('')
    setMessage('')
  }

  async function submitResetPassword(newPassword, confirmPassword) {
    if (!resetTarget) return
    setResetBusy(true)
    setError('')
    try {
      const data = await api.post(`/users/${resetTarget.Id}/reset-password`, {
        new_password: newPassword,
        confirm_password: confirmPassword,
      })
      const uname = resetTarget.Username
      setResetTarget(null)
      setMessage(data.message || `رمز کاربر «${uname}» بازنشانی شد`)
    } catch (err) {
      // خطا داخل مودال هم دیده شود
      setError(err.message)
      throw err
    } finally {
      setResetBusy(false)
    }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      if (form.role_code === 'teacher' && !form.teacher_ref) {
        throw new Error('پروفایل مدرس را انتخاب کنید')
      }
      if (form.role_code === 'student' && !form.student_ref) {
        throw new Error('پروفایل زبان‌آموز را انتخاب کنید')
      }

      if (
        editId &&
        form.role_code === 'teacher' &&
        originalTeacherRef &&
        form.teacher_ref &&
        form.teacher_ref !== originalTeacherRef
      ) {
        const ok = await askConfirm({
          title: 'تأیید جابه‌جایی اتصال',
          message: 'این حساب از پروفایل مدرس قبلی جدا و به پروفایل جدید وصل می‌شود. مطمئن هستید؟',
          confirmLabel: 'بله، وصل کن',
          danger: true,
        })
        if (!ok) {
          setBusy(false)
          return
        }
      }
      if (
        editId &&
        form.role_code === 'student' &&
        originalStudentRef &&
        form.student_ref &&
        form.student_ref !== originalStudentRef
      ) {
        const ok = await askConfirm({
          title: 'تأیید جابه‌جایی اتصال',
          message: 'این حساب از پروفایل زبان‌آموز قبلی جدا و به پروفایل جدید وصل می‌شود. مطمئن هستید؟',
          confirmLabel: 'بله، وصل کن',
          danger: true,
        })
        if (!ok) {
          setBusy(false)
          return
        }
      }

      const payload = {
        full_name: form.full_name.trim(),
        email: form.email.trim() || null,
        role_code: form.role_code,
        teacher_ref: form.role_code === 'teacher' ? Number(form.teacher_ref) : null,
        student_ref: form.role_code === 'student' ? Number(form.student_ref) : null,
        is_active: form.is_active === '1',
      }
      if (editId) {
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
      {confirmDialog}
      <PasswordResetDialog
        open={Boolean(resetTarget)}
        username={resetTarget?.Username || ''}
        fullName={resetTarget?.FullName || ''}
        busy={resetBusy}
        error={error}
        onCancel={() => {
          if (!resetBusy) {
            setResetTarget(null)
            setError('')
          }
        }}
        onSubmit={submitResetPassword}
      />
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">کاربران و دسترسی‌ها</h1>
          <p className="muted mb-0">
            هر حساب کاربری حداکثر به یک پروفایل مدرس یا زبان‌آموز وصل می‌شود — پروفایل‌های قبلاً متصل در فهرست انتخاب نیستند
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
            {editId && (
              <div className="col-md-4">
                <label className="form-label">نام کاربری</label>
                <input className="form-control" value={form.username} disabled readOnly />
              </div>
            )}
            {!editId && (
              <div className="col-md-4">
                <label className="form-label">رمز عبور</label>
                <input
                  type="password"
                  className="form-control"
                  required
                  minLength={8}
                  value={form.password}
                  onChange={(e) => setForm((p) => ({ ...p, password: e.target.value }))}
                  autoComplete="new-password"
                />
              </div>
            )}
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
                onChange={onRoleChange}
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

            {needsProfile && (
              <div className="col-12">
                <div className="user-link-box">
                  <div className="d-flex flex-wrap justify-content-between align-items-start gap-2 mb-2">
                    <div>
                      <div className="fw-bold">
                        {form.role_code === 'teacher' ? 'اتصال به پروفایل مدرس' : 'اتصال به پروفایل زبان‌آموز'}
                      </div>
                      <div className="small text-muted">
                        فقط پروفایل‌هایی که هنوز حساب کاربری ندارند قابل انتخاب‌اند.
                        {form.role_code === 'teacher' ? (
                          <>
                            {' '}اگر مدرس جدید است ابتدا از{' '}
                            <Link to="/teachers">فهرست مدرسان</Link> پروفایل بسازید.
                          </>
                        ) : (
                          <>
                            {' '}اگر زبان‌آموز جدید است ابتدا از{' '}
                            <Link to="/students">فهرست زبان‌آموزان</Link> پروفایل بسازید.
                          </>
                        )}
                      </div>
                    </div>
                    {hasExistingLink && !linkUnlocked && (
                      <button
                        type="button"
                        className="btn btn-sm btn-outline-warning rounded-pill"
                        onClick={unlockLinkChange}
                      >
                        تغییر اتصال…
                      </button>
                    )}
                  </div>

                  {hasExistingLink && !linkUnlocked && (
                    <div className="user-link-locked">
                      <i className="bi bi-link-45deg fs-4 text-brand" />
                      <div>
                        <div className="fw-semibold">
                          {form.role_code === 'teacher'
                            ? profileLabel(linkedTeacher || { FirstName: 'مدرس', LastName: `#${form.teacher_ref}` })
                            : profileLabel(linkedStudent || { FirstName: 'زبان‌آموز', LastName: `#${form.student_ref}` })}
                        </div>
                        <div className="small text-muted">
                          این حساب هم‌اکنون به این پروفایل قفل شده است. برای جابه‌جایی روی «تغییر اتصال» بزنید.
                        </div>
                      </div>
                    </div>
                  )}

                  {showLinkPicker && form.role_code === 'teacher' && (
                    <>
                      <VazirSelect
                        required
                        value={form.teacher_ref}
                        onChange={(v) => setForm((p) => ({ ...p, teacher_ref: v }))}
                        placeholder="انتخاب مدرس آزاد"
                        options={availableTeachers.map((t) => ({
                          value: String(t.Id),
                          label: profileLabel(t),
                        }))}
                      />
                      {!availableTeachers.length && (
                        <div className="form-text text-danger mt-1">
                          مدرس آزادی باقی نمانده — یا همه وصل‌اند یا باید پروفایل جدید بسازید.
                        </div>
                      )}
                    </>
                  )}

                  {showLinkPicker && form.role_code === 'student' && (
                    <>
                      <VazirSelect
                        required
                        value={form.student_ref}
                        onChange={(v) => setForm((p) => ({ ...p, student_ref: v }))}
                        placeholder="انتخاب زبان‌آموز آزاد"
                        options={availableStudents.map((s) => ({
                          value: String(s.Id),
                          label: profileLabel(s),
                        }))}
                      />
                      {!availableStudents.length && (
                        <div className="form-text text-danger mt-1">
                          زبان‌آموز آزادی باقی نمانده — یا همه وصل‌اند یا باید پروفایل جدید بسازید.
                        </div>
                      )}
                    </>
                  )}
                </div>
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
            <strong>مالی:</strong> فقط پرداخت‌ها و گزارش داشبورد — بدون ثبت‌نام
          </li>
          <li>
            <strong>مدرس / زبان‌آموز:</strong> هر حساب فقط به یک پروفایل آزاد وصل می‌شود؛ دو نفر نمی‌توانند یک پروفایل را شریک شوند
          </li>
          <li>
            <strong>مدیر:</strong> همه موارد + ایجاد کاربران و بازنشانی رمز از دکمه کلید در جدول
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
                <th>اتصال پروفایل</th>
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
                    {row.TeacherName ? (
                      <span>
                        <i className="bi bi-person-workspace me-1" />
                        مدرس: {row.TeacherName}
                      </span>
                    ) : null}
                    {row.StudentName ? (
                      <span>
                        <i className="bi bi-mortarboard me-1" />
                        زبان‌آموز: {row.StudentName}
                      </span>
                    ) : null}
                    {!row.TeacherName && !row.StudentName ? (
                      <span className="text-muted">بدون اتصال</span>
                    ) : null}
                  </td>
                  <td>{row.IsActive ? 'فعال' : 'غیرفعال'}</td>
                  <td className="text-nowrap">
                    <RowActions
                      onEdit={() => startEdit(row)}
                      onResetPassword={() => startResetPassword(row)}
                    />
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
