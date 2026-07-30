import { useEffect, useState } from 'react'
import { api } from '../api/client'
import Loading from '../components/Loading'
import PaginationBar from '../components/PaginationBar'
import RowActions from '../components/RowActions'
import { useClientPagination } from '../hooks/useClientPagination'
import { useConfirmDialog } from '../hooks/useConfirmDialog.jsx'

const emptyBranch = { name: '', address: '', phone: '' }

export default function Lookups() {
  const [askConfirm, confirmDialog] = useConfirmDialog()
  const [sessionTypes, setSessionTypes] = useState([])
  const [branches, setBranches] = useState([])
  const [stSearch, setStSearch] = useState('')
  const [brSearch, setBrSearch] = useState('')
  const [stName, setStName] = useState('')
  const [stEditId, setStEditId] = useState(null)
  const [branch, setBranch] = useState(emptyBranch)
  const [brEditId, setBrEditId] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const stPaging = useClientPagination(sessionTypes)
  const brPaging = useClientPagination(branches)

  async function load(stQ = stSearch, brQ = brSearch) {
    setLoading(true)
    try {
      const stQuery = stQ.trim() ? `?search=${encodeURIComponent(stQ.trim())}` : ''
      const brQuery = brQ.trim() ? `?search=${encodeURIComponent(brQ.trim())}` : ''
      const [st, br] = await Promise.all([
        api.get(`/session-types${stQuery}`),
        api.get(`/branches${brQuery}`),
      ])
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

  useEffect(() => {
    const t = setTimeout(() => load(stSearch, brSearch), 250)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stSearch, brSearch])

  function resetSessionType() {
    setStEditId(null)
    setStName('')
  }

  function startEditSessionType(row) {
    setStEditId(row.Id)
    setStName(row.Name || '')
    setMessage('')
    setError('')
  }

  async function submitSessionType(e) {
    e.preventDefault()
    setMessage('')
    setError('')
    try {
      const payload = { name: stName.trim() }
      if (stEditId) {
        await api.put(`/session-types/${stEditId}`, payload)
        setMessage('نوع جلسه ویرایش شد')
      } else {
        await api.post('/session-types', payload)
        setMessage('نوع جلسه ثبت شد')
      }
      resetSessionType()
      await load(stSearch, brSearch)
    } catch (err) {
      setError(err.message)
    }
  }

  async function deleteSessionType(row) {
    const ok = await askConfirm({
      title: 'حذف نوع جلسه',
      message: 'این نوع جلسه حذف می‌شود؛ در صورت استفاده در جلسات، ممکن است عملیات رد شود.',
      confirmLabel: 'حذف نوع جلسه',
      details: [
        { label: 'نام', value: row.Name },
        { label: 'شناسه', value: row.Id },
      ],
    })
    if (!ok) return
    setMessage('')
    setError('')
    try {
      await api.delete(`/session-types/${row.Id}`)
      setMessage('نوع جلسه حذف شد')
      if (stEditId === row.Id) resetSessionType()
      await load(stSearch, brSearch)
    } catch (err) {
      setError(err.message)
    }
  }

  function resetBranch() {
    setBrEditId(null)
    setBranch(emptyBranch)
  }

  function startEditBranch(row) {
    setBrEditId(row.Id)
    setBranch({
      name: row.Name || '',
      address: row.Address || '',
      phone: row.Phone || '',
    })
    setMessage('')
    setError('')
  }

  async function submitBranch(e) {
    e.preventDefault()
    setMessage('')
    setError('')
    try {
      const payload = {
        name: branch.name.trim(),
        address: branch.address.trim() || null,
        phone: branch.phone.trim() || null,
      }
      if (brEditId) {
        await api.put(`/branches/${brEditId}`, payload)
        setMessage('شعبه ویرایش شد')
      } else {
        await api.post('/branches', payload)
        setMessage('شعبه ثبت شد')
      }
      resetBranch()
      await load(stSearch, brSearch)
    } catch (err) {
      setError(err.message)
    }
  }

  async function deleteBranch(row) {
    const ok = await askConfirm({
      title: 'حذف شعبه',
      message: 'این شعبه آرشیو می‌شود و از فهرست فعال خارج خواهد شد.',
      confirmLabel: 'آرشیو شعبه',
      details: [
        { label: 'نام شعبه', value: row.Name },
        { label: 'تلفن', value: row.Phone },
        { label: 'آدرس', value: row.Address },
      ],
    })
    if (!ok) return
    setMessage('')
    setError('')
    try {
      await api.delete(`/branches/${row.Id}`)
      setMessage('شعبه آرشیو شد')
      if (brEditId === row.Id) resetBranch()
      await load(stSearch, brSearch)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="container py-4">
      {confirmDialog}
      <div className="page-head">
        <h1 className="section-title h3 mb-1">اطلاعات پایه</h1>
        <p className="muted mb-0">نوع جلسه و شعب</p>
      </div>

      {message && <div className="alert alert-success py-2">{message}</div>}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      <div className="row g-3">
        <div className="col-lg-6">
          <div className="create-panel h-100">
            <div className="d-flex justify-content-between align-items-center mb-3">
              <h2 className="h6 fw-bold mb-0">
                {stEditId ? `ویرایش نوع جلسه #${stEditId}` : 'ثبت نوع جلسه'}
              </h2>
              {stEditId && (
                <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetSessionType}>
                  انصراف
                </button>
              )}
            </div>
            <form className="row g-2" onSubmit={submitSessionType}>
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
                <button className="btn btn-brand rounded-pill">{stEditId ? 'ذخیره' : 'ثبت'}</button>
              </div>
            </form>
            <input
              className="form-control mt-3"
              placeholder="جستجوی نوع جلسه..."
              value={stSearch}
              onChange={(e) => setStSearch(e.target.value)}
            />
            {loading ? (
              <Loading />
            ) : (
              <>
                <ul className="mt-3 mb-0 list-unstyled list-zebra">
                  {stPaging.slice.map((s) => (
                    <li key={s.Id} className="py-1 border-bottom d-flex justify-content-between align-items-center">
                      <span>
                        {s.Id}. {s.Name}
                      </span>
                      <span className="text-nowrap">
                        <RowActions
                          onEdit={() => startEditSessionType(s)}
                          onDelete={() => deleteSessionType(s)}
                        />
                      </span>
                    </li>
                  ))}
                  {!sessionTypes.length && <li className="py-2 muted">موردی یافت نشد</li>}
                </ul>
                <PaginationBar
                  page={stPaging.page}
                  totalPages={stPaging.totalPages}
                  total={stPaging.total}
                  pageSize={stPaging.pageSize}
                  from={stPaging.from}
                  to={stPaging.to}
                  onChange={stPaging.setPage}
                />
              </>
            )}
          </div>
        </div>
        <div className="col-lg-6">
          <div className="create-panel h-100">
            <div className="d-flex justify-content-between align-items-center mb-3">
              <h2 className="h6 fw-bold mb-0">
                {brEditId ? `ویرایش شعبه #${brEditId}` : 'ثبت شعبه'}
              </h2>
              {brEditId && (
                <button type="button" className="btn btn-sm btn-outline-secondary rounded-pill" onClick={resetBranch}>
                  انصراف
                </button>
              )}
            </div>
            <form className="row g-2" onSubmit={submitBranch}>
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
                <button className="btn btn-brand rounded-pill">{brEditId ? 'ذخیره' : 'ثبت شعبه'}</button>
              </div>
            </form>
            <input
              className="form-control mt-3"
              placeholder="جستجوی شعبه..."
              value={brSearch}
              onChange={(e) => setBrSearch(e.target.value)}
            />
            {loading ? (
              <Loading />
            ) : (
              <>
                <ul className="mt-3 mb-0 list-unstyled list-zebra">
                  {brPaging.slice.map((b) => (
                    <li key={b.Id} className="py-1 border-bottom d-flex justify-content-between align-items-center">
                      <span>
                        <strong>{b.Name}</strong>
                        {b.Address ? ` — ${b.Address}` : ''}
                      </span>
                      <span className="text-nowrap">
                        <RowActions onEdit={() => startEditBranch(b)} onDelete={() => deleteBranch(b)} />
                      </span>
                    </li>
                  ))}
                  {!branches.length && <li className="py-2 muted">موردی یافت نشد</li>}
                </ul>
                <PaginationBar
                  page={brPaging.page}
                  totalPages={brPaging.totalPages}
                  total={brPaging.total}
                  pageSize={brPaging.pageSize}
                  from={brPaging.from}
                  to={brPaging.to}
                  onChange={brPaging.setPage}
                />
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
