import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard', { replace: true })
    }
  }, [isAuthenticated, navigate])

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setBusy(true)
    try {
      await login(username.trim(), password)
      navigate(location.state?.from || '/dashboard', { replace: true })
    } catch (err) {
      setError(err.message || 'ورود ناموفق بود')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="auth-wrap container">
      <div className="auth-panel fade-up">
        <div className="text-center mb-4">
          <div className="brand-badge mx-auto mb-2" style={{ width: 48, height: 48, fontSize: 22 }}>
            ل
          </div>
          <h1 className="h4 fw-bold mb-1">ورود به سامانه لیمز</h1>
          <p className="muted mb-0">نام کاربری و رمز عبور خود را وارد کنید</p>
        </div>

        {error && <div className="alert alert-danger py-2">{error}</div>}

        <form onSubmit={handleSubmit} className="d-grid gap-3">
          <div>
            <label className="form-label">نام کاربری</label>
            <input
              className="form-control"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              autoComplete="username"
              required
            />
          </div>
          <div>
            <label className="form-label">رمز عبور</label>
            <input
              type="password"
              className="form-control"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              required
            />
          </div>
          <button className="btn btn-brand rounded-pill py-2" disabled={busy}>
            {busy ? 'در حال ورود...' : 'ورود'}
          </button>
        </form>

        <div className="mt-3 small muted text-center">
          حساب ندارید؟ <Link to="/register">ثبت‌نام کنید</Link>
          <div className="mt-2">
            <Link to="/">بازگشت به خانه</Link>
          </div>
        </div>
      </div>
    </div>
  )
}
