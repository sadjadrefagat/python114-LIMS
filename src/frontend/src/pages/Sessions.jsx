import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import JalaliDatePicker from '../components/JalaliDatePicker'

export default function Sessions() {
  const [rows, setRows] = useState([])
  const [classes, setClasses] = useState([])
  const [sessionTypes, setSessionTypes] = useState([])
  const [form, setForm] = useState({
    class_ref: '',
    date: '',
    start_time: '10:00',
    end_time: '11:30',
    session_type_ref: '',
    is_makeup: '0',
    meeting_link: '',
    location_address: '',
  })
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function load() {
    setLoading(true)
    try {
      const [s, c, st] = await Promise.all([
        api.get('/sessions'),
        api.get('/classes'),
        api.get('/session-types'),
      ])
      setRows(s.sessions || [])
      setClasses(c.classes || [])
      setSessionTypes(st.session_types || [])
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
      await api.post('/sessions', {
        class_ref: Number(form.class_ref),
        date: form.date,
        start_time: form.start_time,
        end_time: form.end_time,
        session_type_ref: Number(form.session_type_ref),
        is_makeup: form.is_makeup === '1',
        meeting_link: form.meeting_link || null,
        location_address: form.location_address || null,
      })
      setMessage('جلسه ثبت شد')
      setForm((p) => ({ ...p, date: '', meeting_link: '', location_address: '' }))
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head">
        <h1 className="section-title h3 mb-1">جلسات</h1>
        <p className="muted mb-0">زمان‌بندی جلسات کلاس‌ها</p>
      </div>

      <div className="create-panel">
        <h2 className="h6 fw-bold mb-3">ثبت جلسه جدید</h2>
        <form className="row g-2" onSubmit={handleCreate}>
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
            <label className="form-label">تاریخ شمسی</label>
            <JalaliDatePicker
              required
              value={form.date}
              onChange={(v) => setForm((p) => ({ ...p, date: v }))}
            />
          </div>
          <div className="col-md-4">
            <label className="form-label">نوع جلسه</label>
            <VazirSelect
              required
              value={form.session_type_ref}
              onChange={(v) => setForm((p) => ({ ...p, session_type_ref: v }))}
              options={sessionTypes.map((s) => ({ value: String(s.Id), label: s.Name }))}
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">ساعت شروع</label>
            <input
              className="form-control"
              value={form.start_time}
              onChange={(e) => setForm((p) => ({ ...p, start_time: e.target.value }))}
              placeholder="10:00"
              required
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">ساعت پایان</label>
            <input
              className="form-control"
              value={form.end_time}
              onChange={(e) => setForm((p) => ({ ...p, end_time: e.target.value }))}
              placeholder="11:30"
              required
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">جبرانی؟</label>
            <VazirSelect
              value={form.is_makeup}
              onChange={(v) => setForm((p) => ({ ...p, is_makeup: v }))}
              options={[
                { value: '0', label: 'خیر' },
                { value: '1', label: 'بله' },
              ]}
            />
          </div>
          <div className="col-md-3">
            <label className="form-label">لینک آنلاین</label>
            <input
              className="form-control"
              value={form.meeting_link}
              onChange={(e) => setForm((p) => ({ ...p, meeting_link: e.target.value }))}
            />
          </div>
          <div className="col-md-9">
            <label className="form-label">آدرس حضوری</label>
            <input
              className="form-control"
              value={form.location_address}
              onChange={(e) => setForm((p) => ({ ...p, location_address: e.target.value }))}
            />
          </div>
          <div className="col-md-3 d-grid align-items-end">
            <button className="btn btn-brand rounded-pill" disabled={busy}>
              {busy ? '...' : 'ثبت جلسه'}
            </button>
          </div>
        </form>
      </div>

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}
      {loading ? (
        <Loading />
      ) : (
        <div className="panel table-responsive">
          <table className="table mb-0 align-middle">
            <thead>
              <tr>
                <th>کد</th>
                <th>دوره</th>
                <th>تاریخ</th>
                <th>ساعت</th>
                <th>نوع</th>
                <th>وضعیت</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.Id}>
                  <td>{row.Id}</td>
                  <td>{row.CourseName}</td>
                  <td>{row.Date}</td>
                  <td>
                    {row.StartTime} - {row.EndTime}
                  </td>
                  <td>{row.SessionTypeName}</td>
                  <td>{row.Status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
