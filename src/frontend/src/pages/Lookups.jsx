import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'

export default function Lookups() {
  const [sessionTypes, setSessionTypes] = useState([])
  const [branches, setBranches] = useState([])
  const [stName, setStName] = useState('')
  const [branch, setBranch] = useState({ name: '', address: '', phone: '' })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function load() {
    setLoading(true)
    try {
      const [st, br] = await Promise.all([api.get('/session-types'), api.get('/branches')])
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

  async function createSessionType(e) {
    e.preventDefault()
    setMessage('')
    setError('')
    try {
      await api.post('/session-types', { name: stName.trim() })
      setStName('')
      setMessage('نوع جلسه ثبت شد')
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  async function createBranch(e) {
    e.preventDefault()
    setMessage('')
    setError('')
    try {
      await api.post('/branches', {
        name: branch.name.trim(),
        address: branch.address.trim() || null,
        phone: branch.phone.trim() || null,
      })
      setBranch({ name: '', address: '', phone: '' })
      setMessage('شعبه ثبت شد')
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container py-4">
      <div className="page-head">
        <h1 className="section-title h3 mb-1">اطلاعات پایه</h1>
        <p className="muted mb-0">نوع جلسه و شعب</p>
      </div>

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      <div className="row g-3">
        <div className="col-lg-6">
          <div className="create-panel h-100">
            <h2 className="h6 fw-bold mb-3">ثبت نوع جلسه</h2>
            <form className="row g-2" onSubmit={createSessionType}>
              <div className="col-8">
                <input
                  className="form-control"
                  value={stName}
                  onChange={(e) => setStName(e.target.value)}
                  placeholder="مثلاً حضوری"
                  required
                />
              </div>
              <div className="col-4 d-grid">
                <button className="btn btn-brand rounded-pill">ثبت</button>
              </div>
            </form>
            {loading ? (
              <Loading />
            ) : (
              <ul className="mt-3 mb-0 list-unstyled">
                {sessionTypes.map((s) => (
                  <li key={s.Id} className="py-1 border-bottom">
                    {s.Id}. {s.Name}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
        <div className="col-lg-6">
          <div className="create-panel h-100">
            <h2 className="h6 fw-bold mb-3">ثبت شعبه</h2>
            <form className="row g-2" onSubmit={createBranch}>
              <div className="col-12">
                <input
                  className="form-control"
                  value={branch.name}
                  onChange={(e) => setBranch((p) => ({ ...p, name: e.target.value }))}
                  placeholder="نام شعبه"
                  required
                />
              </div>
              <div className="col-md-7">
                <input
                  className="form-control"
                  value={branch.address}
                  onChange={(e) => setBranch((p) => ({ ...p, address: e.target.value }))}
                  placeholder="آدرس"
                />
              </div>
              <div className="col-md-5">
                <input
                  className="form-control"
                  value={branch.phone}
                  onChange={(e) => setBranch((p) => ({ ...p, phone: e.target.value }))}
                  placeholder="تلفن"
                />
              </div>
              <div className="col-12 d-grid">
                <button className="btn btn-brand rounded-pill">ثبت شعبه</button>
              </div>
            </form>
            {loading ? (
              <Loading />
            ) : (
              <ul className="mt-3 mb-0 list-unstyled">
                {branches.map((b) => (
                  <li key={b.Id} className="py-1 border-bottom">
                    <strong>{b.Name}</strong>
                    {b.Address ? ` — ${b.Address}` : ''}
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
