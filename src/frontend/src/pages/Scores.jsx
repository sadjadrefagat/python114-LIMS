import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker, { todayJalaliString } from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const EXAM_LABEL = {
  placement: 'تعیین سطح',
  midterm: 'میان‌ترم',
  final: 'پایان‌ترم',
  quiz: 'کوییز',
  assignment: 'تکلیف',
}

const emptyForm = {
  student_ref: '',
  registration_ref: '',
  exam_type: 'placement',
  score_value: '',
  max_score: '100',
  exam_date: todayJalaliString(),
  suggested_level_ref: '',
  notes: '',
}

export default function Scores() {
  const { hasRole } = useAuth()
  const canManage = hasRole('admin', 'secretary', 'education', 'teacher')
  const canPlacement = hasRole('admin', 'secretary', 'education')
  const examOptions = useMemo(() => {
    const entries = Object.entries(EXAM_LABEL).filter(([value]) => canPlacement || value !== 'placement')
    return entries.map(([value, label]) => ({ value, label }))
  }, [canPlacement])
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [rows, setRows] = useState([])
  const [students, setStudents] = useState([])
  const [enrollments, setEnrollments] = useState([])
  const [levels, setLevels] = useState([])
  const [search, setSearch] = useState('')
  const [examFilter, setExamFilter] = useState(canPlacement ? 'placement' : '')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState({
    ...emptyForm,
    exam_type: canPlacement ? 'placement' : 'midterm',
  })

  async function loadStudentsForForm() {
    // اول فهرست کامل (برای مدرس هم مجاز است)؛ اگر نشد از زبان‌آموزان کلاس‌های خودش
    try {
      const data = await api.get('/students')
      return data.students || []
    } catch (err) {
      if (!hasRole('teacher')) throw err
      const data = await api.get('/me/teaching/students')
      const map = new Map()
      for (const s of data.students || []) {
        if (!map.has(s.Id)) map.set(s.Id, s)
      }
      return [...map.values()]
    }
  }

  async function loadEnrollmentsForForm() {
    try {
      const data = await api.get('/enrollments?include_withdrawn=true')
      return data.enrollments || []
    } catch (err) {
      if (!hasRole('teacher')) throw err
      // برای مدرس: ثبت‌نام‌های زبان‌آموزان کلاس‌هایش
      const data = await api.get('/me/teaching/students')
      return (data.students || []).map((s) => ({
        Id: s.EnrollmentId,
        StudentRef: s.Id,
        CourseName: s.CourseName,
        Status: s.EnrollmentStatus,
      })).filter((e) => e.Id)
    }
  }

  async function load() {
    setLoading(true)
    setError('')
    try {
      const qs = new URLSearchParams()
      if (examFilter) qs.set('exam_type', examFilter)
      if (search.trim()) qs.set('search', search.trim())

      const scRes = await api.get(`/scores${qs.toString() ? `?${qs}` : ''}`)
      setRows(scRes.scores || [])

      const [stList, enList, lvRes] = await Promise.allSettled([
        loadStudentsForForm(),
        loadEnrollmentsForForm(),
        api.get('/levels'),
      ])

      if (stList.status === 'fulfilled') setStudents(stList.value)
      else {
        setStudents([])
        console.warn('students', stList.reason)
      }
      if (enList.status === 'fulfilled') setEnrollments(enList.value)
      else setEnrollments([])
      if (lvRes.status === 'fulfilled') setLevels(lvRes.value.levels || [])

      if (stList.status === 'rejected' && enList.status === 'rejected') {
        setError(
          stList.reason?.message ||
            'فهرست زبان‌آموزان بارگذاری نشد. اگر مدرس هستید، بک‌اند را ری‌استارت کنید.',
        )
      }
    } catch (err) {
      setError(err.message)
      setRows([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (!canManage) return undefined
    load()
    return undefined
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canManage, examFilter])

  const filteredPaging = useClientPagination(rows)

  const enrollmentOptions = useMemo(() => {
    const list = form.student_ref
      ? enrollments.filter((e) => String(e.StudentRef) === String(form.student_ref))
      : enrollments
    return list.map((e) => ({
      value: String(e.Id),
      label: `#${e.Id} · ${e.CourseName || 'دوره'} · ${e.Status || ''}`,
    }))
  }, [enrollments, form.student_ref])

  const isPlacement = form.exam_type === 'placement'
  const defaultExamType = canPlacement
    ? examFilter || 'placement'
    : examFilter && examFilter !== 'placement'
      ? examFilter
      : 'midterm'

  function resetForm() {
    setEditId(null)
    setForm({ ...emptyForm, exam_date: todayJalaliString(), exam_type: defaultExamType })
    setShowForm(false)
  }

  function startCreate() {
    setEditId(null)
    setForm({ ...emptyForm, exam_date: todayJalaliString(), exam_type: defaultExamType })
    setShowForm(true)
    setMessage('')
    setError('')
  }

  function startEdit(row) {
    if (!canPlacement && row.ExamType === 'placement') {
      setError('مدرس مجاز به مشاهده یا ویرایش نتایج تعیین سطح نیست')
      return
    }
    setEditId(row.Id)
    setForm({
      student_ref: String(row.StudentRef || ''),
      registration_ref: row.RegistrationRef != null ? String(row.RegistrationRef) : '',
      exam_type: row.ExamType || defaultExamType,
      score_value: row.ScoreValue != null ? String(row.ScoreValue) : '',
      max_score: row.MaxScore != null ? String(row.MaxScore) : '100',
      exam_date: row.ExamDate || todayJalaliString(),
      suggested_level_ref: row.SuggestedLevelRef != null ? String(row.SuggestedLevelRef) : '',
      notes: row.Notes || '',
    })
    setShowForm(true)
    setMessage('')
    setError('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!form.student_ref) {
      setError('زبان‌آموز را انتخاب کنید')
      return
    }
    if (!isPlacement && !form.registration_ref) {
      setError('برای این نوع آزمون، ثبت‌نام مرتبط الزامی است')
      return
    }
    const scoreValue = Number(form.score_value)
    const maxScore = Number(form.max_score)
    if (!Number.isFinite(scoreValue) || scoreValue < 0) {
      setError('نمره نامعتبر است')
      return
    }
    if (!Number.isFinite(maxScore) || maxScore <= 0) {
      setError('سقف نمره نامعتبر است')
      return
    }
    if (scoreValue > maxScore) {
      setError('نمره نمی‌تواند از سقف بیشتر باشد')
      return
    }

    setBusy(true)
    setError('')
    setMessage('')
    const payload = {
      student_ref: Number(form.student_ref),
      registration_ref: form.registration_ref ? Number(form.registration_ref) : null,
      exam_type: form.exam_type,
      score_value: scoreValue,
      max_score: maxScore,
      exam_date: form.exam_date || null,
      suggested_level_ref: form.suggested_level_ref ? Number(form.suggested_level_ref) : null,
      notes: form.notes.trim() || null,
    }
    try {
      if (editId) {
        await api.put(`/scores/${editId}`, {
          ...payload,
          clear_registration: !form.registration_ref,
          clear_suggested_level: !form.suggested_level_ref,
        })
        setMessage('نتیجه آزمون ویرایش شد')
      } else {
        await api.post('/scores', payload)
        setMessage('نتیجه آزمون ثبت شد')
      }
      resetForm()
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function handleDelete(row) {
    const ok = await askConfirm({
      title: 'حذف نتیجه آزمون',
      message: 'این نتیجه برای همیشه حذف می‌شود.',
      confirmLabel: 'حذف',
      cancelLabel: 'بازگشت',
      details: [
        { label: 'کد', value: `#${row.Id}` },
        { label: 'زبان‌آموز', value: row.StudentName },
        { label: 'نوع', value: EXAM_LABEL[row.ExamType] || row.ExamType },
        { label: 'نمره', value: `${row.ScoreValue} / ${row.MaxScore}` },
        { label: 'سطح پیشنهادی', value: row.SuggestedLevelName },
        { label: 'تاریخ', value: row.ExamDate },
      ],
    })
    if (!ok) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/scores/${row.Id}`)
      setRows((prev) => prev.filter((r) => r.Id !== row.Id))
      setMessage('نتیجه آزمون حذف شد')
      if (editId === row.Id) resetForm()
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  if (!canManage) {
    return (
      <div className="container py-4">
        <div className="alert alert-warning">دسترسی به نمرات و تعیین سطح ندارید.</div>
      </div>
    )
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head d-flex flex-wrap justify-content-between gap-2">
        <div>
          <h1 className="section-title h3 mb-1">{canPlacement ? 'نمرات و تعیین سطح' : 'نمرات'}</h1>
          <p className="muted mb-0">
            {canPlacement
              ? 'ثبت، ویرایش و حذف نتایج آزمون تعیین سطح و سایر نمرات زبان‌آموزان'
              : 'ثبت و مدیریت نمرات کلاس (میان‌ترم، پایان‌ترم، کوییز و تکلیف) — نتایج تعیین سطح فقط برای آموزشگاه قابل مشاهده است'}
          </p>
        </div>
        <div className="d-flex flex-wrap gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 200 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') load()
            }}
          />
          <div style={{ minWidth: 160 }}>
            <VazirSelect
              value={examFilter}
              onChange={setExamFilter}
              options={[
                { value: '', label: 'همه انواع' },
                ...examOptions,
              ]}
            />
          </div>
          <button type="button" className="btn btn-outline-secondary rounded-pill" onClick={load}>
            اعمال
          </button>
          <button type="button" className="btn btn-brand rounded-pill" onClick={startCreate}>
            ثبت نتیجه
          </button>
        </div>
      </div>

      {showForm && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش نتیجه #${editId}` : 'ثبت نتیجه آزمون'}
            </h2>
            <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
              انصراف
            </button>
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">زبان‌آموز</label>
              <VazirSelect
                required
                value={form.student_ref}
                onChange={(v) => setForm((p) => ({ ...p, student_ref: v, registration_ref: '' }))}
                options={students.map((s) => ({
                  value: String(s.Id),
                  label: `${s.FirstName} ${s.LastName}`,
                }))}
              />
              {!students.length && (
                <div className="form-text text-danger">فهرست زبان‌آموزان خالی است یا دسترسی ندارید.</div>
              )}
            </div>
            <div className="col-md-4">
              <label className="form-label">نوع آزمون</label>
              <VazirSelect
                value={form.exam_type}
                onChange={(v) => setForm((p) => ({ ...p, exam_type: v }))}
                options={examOptions}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">
                ثبت‌نام مرتبط {isPlacement ? '(اختیاری)' : ''}
              </label>
              <VazirSelect
                required={!isPlacement}
                value={form.registration_ref}
                onChange={(v) => setForm((p) => ({ ...p, registration_ref: v }))}
                placeholder={isPlacement ? 'بدون ثبت‌نام' : 'انتخاب ثبت‌نام'}
                options={[{ value: '', label: isPlacement ? '— بدون ثبت‌نام —' : 'انتخاب کنید' }, ...enrollmentOptions]}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">نمره</label>
              <input
                className="form-control"
                type="number"
                min="0"
                step="0.01"
                required
                value={form.score_value}
                onChange={(e) => setForm((p) => ({ ...p, score_value: e.target.value }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">سقف نمره</label>
              <input
                className="form-control"
                type="number"
                min="1"
                step="0.01"
                required
                value={form.max_score}
                onChange={(e) => setForm((p) => ({ ...p, max_score: e.target.value }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">تاریخ آزمون</label>
              <JalaliDatePicker
                value={form.exam_date}
                onChange={(v) => setForm((p) => ({ ...p, exam_date: v }))}
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">سطح پیشنهادی</label>
              <VazirSelect
                value={form.suggested_level_ref}
                onChange={(v) => setForm((p) => ({ ...p, suggested_level_ref: v }))}
                placeholder="انتخاب سطح"
                options={[
                  { value: '', label: '— بدون پیشنهاد —' },
                  ...levels.map((l) => ({
                    value: String(l.Id),
                    label: l.Code ? `${l.Name} (${l.Code})` : l.Name,
                  })),
                ]}
              />
            </div>
            <div className="col-12">
              <label className="form-label">توضیح / مهارت‌ها</label>
              <input
                className="form-control"
                value={form.notes}
                onChange={(e) => setForm((p) => ({ ...p, notes: e.target.value }))}
                placeholder="مثلاً Listening خوب، Writing ضعیف"
              />
            </div>
            <div className="col-12">
              <button className="btn btn-brand rounded-pill px-4" disabled={busy}>
                {busy ? '...' : editId ? 'ذخیره تغییرات' : 'ثبت نتیجه'}
              </button>
            </div>
          </form>
        </div>
      )}

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table table-zebra mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>زبان‌آموز</th>
                <th>نوع</th>
                <th>نمره</th>
                <th>سطح پیشنهادی</th>
                <th>ثبت‌نام / دوره</th>
                <th>تاریخ</th>
                <th>توضیح</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filteredPaging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.StudentName || '—'}</td>
                  <td>
                    <span className="chip chip-teal">{EXAM_LABEL[row.ExamType] || row.ExamType}</span>
                  </td>
                  <td className="text-nowrap fw-semibold">
                    {row.ScoreValue} <span className="text-muted fw-normal">/ {row.MaxScore}</span>
                  </td>
                  <td>{row.SuggestedLevelName || '—'}</td>
                  <td>
                    {row.RegistrationRef ? (
                      <>
                        #{row.RegistrationRef}
                        {row.CourseName ? ` · ${row.CourseName}` : ''}
                      </>
                    ) : (
                      <span className="text-muted small">بدون ثبت‌نام</span>
                    )}
                  </td>
                  <td>{row.ExamDate || '—'}</td>
                  <td className="small">{row.Notes || '—'}</td>
                  <td className="text-nowrap">
                    <RowActions onEdit={() => startEdit(row)} onDelete={() => handleDelete(row)} />
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={9} className="text-center muted py-4">
                    نتیجه‌ای ثبت نشده است
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          <PaginationBar
            page={filteredPaging.page}
            totalPages={filteredPaging.totalPages}
            total={filteredPaging.total}
            pageSize={filteredPaging.pageSize}
            from={filteredPaging.from}
            to={filteredPaging.to}
            onChange={filteredPaging.setPage}
          />
        </div>
      )}
    </div>
  )
}
