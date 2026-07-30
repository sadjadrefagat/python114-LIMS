import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker from '../components/JalaliDatePicker'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'

const statusMap = {
  pending_payment: 'در انتظار پرداخت',
  pending_approval: 'در انتظار تأیید',
  active: 'فعال',
  frozen: 'معلق',
  completed: 'تکمیل‌شده',
  withdrawn: 'انصراف',
  transferred: 'انتقال',
}

const financeMap = {
  debtor: 'بدهکار',
  settled: 'تسویه‌شده',
  partial: 'جزئی',
}

const emptyForm = {
  student_refs: [],
  student_ref: '',
  class_ref: '',
  date: '',
  status: 'pending_payment',
  financial_status: 'debtor',
  withdraw_reason: '',
}

export default function Enrollments() {
  const [rows, setRows] = useState([])
  const [students, setStudents] = useState([])
  const [classes, setClasses] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [editId, setEditId] = useState(null)
  const [form, setForm] = useState(emptyForm)
  const paging = useClientPagination(rows)

  async function load(q = search) {
    setLoading(true)
    try {
      const query = q.trim() ? `?search=${encodeURIComponent(q.trim())}` : ''
      const [en, st, cl] = await Promise.all([
        api.get(`/enrollments${query}`),
        api.get('/students'),
        api.get('/classes'),
      ])
      setRows(en.enrollments || [])
      setStudents(st.students || [])
      setClasses(cl.classes || [])
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
      student_refs: [],
      student_ref: String(row.StudentRef || ''),
      class_ref: row.ClassRef ? String(row.ClassRef) : '',
      date: row.Date || '',
      status: row.Status || 'pending_payment',
      financial_status: row.FinancialStatus || 'debtor',
      withdraw_reason: row.WithdrawReason || '',
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

    if (editId && form.status === 'withdrawn' && !form.withdraw_reason.trim()) {
      setError('برای انصراف، دلیل الزامی است')
      setBusy(false)
      return
    }

    if (!editId && !form.student_refs.length) {
      setError('حداقل یک زبان‌آموز انتخاب کنید')
      setBusy(false)
      return
    }

    try {
      if (editId) {
        await api.put(`/enrollments/${editId}`, {
          status: form.status,
          financial_status: form.financial_status,
          withdraw_reason: form.status === 'withdrawn' ? form.withdraw_reason.trim() : null,
        })
        setMessage('ثبت‌نام ویرایش شد')
      } else {
        const payload = {
          student_refs: form.student_refs.map(Number),
          class_ref: Number(form.class_ref),
          date: form.date,
          status: form.status,
          financial_status: form.financial_status,
        }
        const res = await api.post('/enrollments/bulk', payload)
        const n = res.count ?? res.ids?.length ?? form.student_refs.length
        setMessage(n > 1 ? `${n} ثبت‌نام انجام شد` : 'ثبت‌نام انجام شد')
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
    if (!window.confirm(`لغو ثبت‌نام «${row.StudentName}» در «${row.CourseName}»؟`)) return
    setError('')
    setMessage('')
    try {
      await api.delete(`/enrollments/${row.Id}`)
      setMessage('ثبت‌نام به حالت انصراف تغییر یافت')
      if (editId === row.Id) resetForm()
      await load(search)
    } catch (err) {
      setError(err.message)
    }
  }

  const studentOptions = students.map((s) => ({
    value: String(s.Id),
    label: `${s.FirstName} ${s.LastName}`,
  }))

  return (
    <div className="container py-4">
      <div className="page-head d-flex justify-content-between flex-wrap gap-2">
        <div>
          <h1 className="section-title h3 mb-1">ثبت‌نام‌ها</h1>
          <p className="muted mb-0">وضعیت ثبت‌نام زبان‌آموز در کلاس</p>
        </div>
        <div className="d-flex gap-2">
          <input
            className="form-control"
            style={{ maxWidth: 240 }}
            placeholder="جستجو"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button
            className="btn btn-brand rounded-pill"
            onClick={() => (showCreate ? resetForm() : setShowCreate(true))}
          >
            {showCreate ? 'بستن' : 'ثبت‌نام جدید'}
          </button>
        </div>
      </div>

      {showCreate && (
        <div className="create-panel">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h2 className="h6 fw-bold mb-0">
              {editId ? `ویرایش ثبت‌نام #${editId}` : 'ثبت‌نام جدید'}
            </h2>
            {editId && (
              <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetForm}>
                انصراف
              </button>
            )}
          </div>
          <form className="row g-2" onSubmit={handleSubmit}>
            <div className="col-md-4">
              <label className="form-label">
                زبان‌آموز{!editId ? ' (چندتایی)' : ''}
              </label>
              {editId ? (
                <VazirSelect
                  required
                  disabled
                  value={form.student_ref}
                  onChange={(v) => setForm((p) => ({ ...p, student_ref: v }))}
                  options={studentOptions}
                />
              ) : (
                <VazirSelect
                  required
                  multiple
                  placeholder="انتخاب یک یا چند زبان‌آموز"
                  value={form.student_refs}
                  onChange={(v) => setForm((p) => ({ ...p, student_refs: v }))}
                  options={studentOptions}
                />
              )}
            </div>
            <div className="col-md-4">
              <label className="form-label">کلاس</label>
              <VazirSelect
                required
                disabled={Boolean(editId)}
                value={form.class_ref}
                onChange={(v) => setForm((p) => ({ ...p, class_ref: v }))}
                options={classes.map((c) => ({
                  value: String(c.Id),
                  label: `${c.Id} — ${c.CourseName}`,
                }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">تاریخ ثبت‌نام</label>
              <JalaliDatePicker
                required
                disabled={Boolean(editId)}
                value={form.date}
                onChange={(v) => setForm((p) => ({ ...p, date: v }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">وضعیت</label>
              <VazirSelect
                value={form.status}
                onChange={(v) => setForm((p) => ({ ...p, status: v }))}
                options={Object.entries(statusMap).map(([value, label]) => ({ value, label }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">وضعیت مالی</label>
              <VazirSelect
                value={form.financial_status}
                onChange={(v) => setForm((p) => ({ ...p, financial_status: v }))}
                options={Object.entries(financeMap).map(([value, label]) => ({ value, label }))}
              />
            </div>
            {editId && form.status === 'withdrawn' && (
              <div className="col-md-4">
                <label className="form-label">دلیل انصراف</label>
                <input
                  className="form-control"
                  value={form.withdraw_reason}
                  onChange={(e) => setForm((p) => ({ ...p, withdraw_reason: e.target.value }))}
                  required
                />
              </div>
            )}
            <div className="col-md-4 d-grid align-items-end">
              <button className="btn btn-brand rounded-pill" disabled={busy}>
                {busy
                  ? '...'
                  : editId
                    ? 'ذخیره'
                    : form.student_refs.length > 1
                      ? `ثبت ${form.student_refs.length} نفر`
                      : 'ثبت'}
              </button>
            </div>
          </form>
          {!editId && form.student_refs.length > 1 && (
            <p className="small text-muted mb-0 mt-2">
              کلاس، تاریخ، وضعیت و وضعیت مالی برای همهٔ {form.student_refs.length} زبان‌آموز اعمال می‌شود.
            </p>
          )}
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
                <th>زبان‌آموز</th>
                <th>دوره</th>
                <th>کلاس</th>
                <th>تاریخ</th>
                <th>وضعیت</th>
                <th>مالی</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {paging.slice.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.StudentName}</td>
                  <td>{row.CourseName}</td>
                  <td>{row.ClassRef || '—'}</td>
                  <td>{row.Date}</td>
                  <td>
                    <span className="chip chip-teal">{statusMap[row.Status] || row.Status}</span>
                  </td>
                  <td>
                    <span className="chip chip-coral">
                      {financeMap[row.FinancialStatus] || row.FinancialStatus}
                    </span>
                  </td>
                  <td className="text-nowrap">
                    <button type="button" className="btn btn-sm btn-outline-success rounded-pill me-1" onClick={() => startEdit(row)}>
                      ویرایش
                    </button>
                    <button type="button" className="btn btn-sm btn-outline-danger rounded-pill" onClick={() => handleDelete(row)}>
                      حذف
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">ثبت‌نامی یافت نشد.</div>}
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
