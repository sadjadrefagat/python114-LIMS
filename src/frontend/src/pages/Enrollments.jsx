import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker from '../components/JalaliDatePicker'

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

export default function Enrollments() {
  const [rows, setRows] = useState([])
  const [students, setStudents] = useState([])
  const [classes, setClasses] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)
  const [showCreate, setShowCreate] = useState(false)
  const [form, setForm] = useState({
    student_ref: '',
    class_ref: '',
    date: '',
    status: 'pending_payment',
    financial_status: 'debtor',
  })

  async function load() {
    setLoading(true)
    try {
      const [en, st, cl] = await Promise.all([
        api.get('/enrollments'),
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
    load()
  }, [])

  async function handleCreate(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    setMessage('')
    try {
      await api.post('/enrollments', {
        student_ref: Number(form.student_ref),
        class_ref: Number(form.class_ref),
        date: form.date,
        status: form.status,
        financial_status: form.financial_status,
      })
      setMessage('ثبت‌نام انجام شد')
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
          <h1 className="section-title h3 mb-1">ثبت‌نام‌ها</h1>
          <p className="muted mb-0">وضعیت ثبت‌نام زبان‌آموز در کلاس</p>
        </div>
        <button className="btn btn-brand rounded-pill" onClick={() => setShowCreate((v) => !v)}>
          {showCreate ? 'بستن' : 'ثبت‌نام جدید'}
        </button>
      </div>

      {showCreate && (
        <div className="create-panel">
          <form className="row g-2" onSubmit={handleCreate}>
            <div className="col-md-4">
              <label className="form-label">زبان‌آموز</label>
              <VazirSelect
                required
                value={form.student_ref}
                onChange={(v) => setForm((p) => ({ ...p, student_ref: v }))}
                options={students.map((s) => ({
                  value: String(s.Id),
                  label: `${s.FirstName} ${s.LastName}`,
                }))}
              />
            </div>
            <div className="col-md-4">
              <label className="form-label">کلاس</label>
              <VazirSelect
                required
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
            <div className="col-md-4 d-grid align-items-end">
              <button className="btn btn-brand rounded-pill" disabled={busy}>
                {busy ? '...' : 'ثبت'}
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
          <table className="table table-hover mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>زبان‌آموز</th>
                <th>دوره</th>
                <th>کلاس</th>
                <th>تاریخ</th>
                <th>وضعیت</th>
                <th>مالی</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
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
                </tr>
              ))}
            </tbody>
          </table>
          {!rows.length && <div className="empty-state">ثبت‌نامی یافت نشد.</div>}
        </div>
      )}
    </div>
  )
}
