import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'

const initialForm = {
  username: '',
  password: '',
  password_confirm: '',
  email: '',
  first_name: '',
  last_name: '',
  father_name: '',
  mobile: '',
  national_code: '',
  gender: '2',
  birth_date: '',
  target_language_ref: '',
}

export default function Register() {
  const { register, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [form, setForm] = useState(initialForm)
  const [languages, setLanguages] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    if (isAuthenticated) navigate('/dashboard', { replace: true })
  }, [isAuthenticated, navigate])

  useEffect(() => {
    api
      .get('/languages')
      .then((data) => setLanguages(data.languages || []))
      .catch(() => {})
  }, [])

  function update(field, value) {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')

    if (form.password !== form.password_confirm) {
      setError('رمز عبور و تکرار آن یکسان نیست')
      return
    }
    if (form.password.length < 8) {
      setError('رمز عبور حداقل ۸ کاراکتر باشد')
      return
    }
    if (!/^\d{10}$/.test(form.national_code)) {
      setError('کد ملی باید دقیقاً ۱۰ رقم باشد')
      return
    }
    if (!/^\d{4}\/\d{2}\/\d{2}$/.test(form.birth_date)) {
      setError('تاریخ تولد را به صورت 1370/01/15 وارد کنید')
      return
    }

    setBusy(true)
    try {
      await register({
        username: form.username.trim(),
        password: form.password,
        email: form.email.trim() || null,
        first_name: form.first_name.trim(),
        last_name: form.last_name.trim(),
        father_name: form.father_name.trim(),
        mobile: form.mobile.trim(),
        national_code: form.national_code.trim(),
        gender: Number(form.gender),
        birth_date: form.birth_date.trim(),
        target_language_ref: form.target_language_ref
          ? Number(form.target_language_ref)
          : null,
        preferred_ui_language: 'fa',
      })
      navigate('/dashboard', { replace: true })
    } catch (err) {
      setError(err.message || 'ثبت‌نام ناموفق بود')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="auth-wrap container">
      <div className="auth-panel fade-up" style={{ width: 'min(640px, 100%)' }}>
        <div className="text-center mb-4">
          <div className="brand-badge mx-auto mb-2" style={{ width: 48, height: 48, fontSize: 22 }}>
            ل
          </div>
          <h1 className="h4 fw-bold mb-1">ثبت‌نام زبان‌آموز</h1>
          <p className="muted mb-0">بدون تأیید ایمیل؛ بلافاصله وارد پنل می‌شوید</p>
        </div>

        {error && <div className="alert alert-danger py-2">{error}</div>}

        <form onSubmit={handleSubmit} className="row g-3">
          <div className="col-md-6">
            <label className="form-label">نام</label>
            <input
              className="form-control"
              value={form.first_name}
              onChange={(e) => update('first_name', e.target.value)}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">نام خانوادگی</label>
            <input
              className="form-control"
              value={form.last_name}
              onChange={(e) => update('last_name', e.target.value)}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">نام پدر</label>
            <input
              className="form-control"
              value={form.father_name}
              onChange={(e) => update('father_name', e.target.value)}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">کد ملی</label>
            <input
              className="form-control"
              value={form.national_code}
              onChange={(e) => update('national_code', e.target.value.replace(/\D/g, '').slice(0, 10))}
              inputMode="numeric"
              maxLength={10}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">موبایل</label>
            <input
              className="form-control"
              value={form.mobile}
              onChange={(e) => update('mobile', e.target.value)}
              placeholder="0912..."
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">تاریخ تولد (شمسی)</label>
            <input
              className="form-control"
              value={form.birth_date}
              onChange={(e) => update('birth_date', e.target.value)}
              placeholder="1370/01/15"
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">جنسیت</label>
            <select
              className="form-select"
              value={form.gender}
              onChange={(e) => update('gender', e.target.value)}
            >
              <option value="1">خانم</option>
              <option value="2">آقا</option>
            </select>
          </div>
          <div className="col-md-6">
            <label className="form-label">زبان هدف (اختیاری)</label>
            <select
              className="form-select"
              value={form.target_language_ref}
              onChange={(e) => update('target_language_ref', e.target.value)}
            >
              <option value="">انتخاب نشده</option>
              {languages.map((lang) => (
                <option key={lang.Id} value={lang.Id}>
                  {lang.Name}
                </option>
              ))}
            </select>
          </div>
          <div className="col-md-6">
            <label className="form-label">ایمیل (اختیاری)</label>
            <input
              type="email"
              className="form-control"
              value={form.email}
              onChange={(e) => update('email', e.target.value)}
              placeholder="نیازی به تأیید ندارد"
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">نام کاربری</label>
            <input
              className="form-control"
              value={form.username}
              onChange={(e) => update('username', e.target.value)}
              autoComplete="username"
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">رمز عبور</label>
            <input
              type="password"
              className="form-control"
              value={form.password}
              onChange={(e) => update('password', e.target.value)}
              autoComplete="new-password"
              minLength={8}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">تکرار رمز عبور</label>
            <input
              type="password"
              className="form-control"
              value={form.password_confirm}
              onChange={(e) => update('password_confirm', e.target.value)}
              autoComplete="new-password"
              minLength={8}
              required
            />
          </div>
          <div className="col-12 d-grid">
            <button className="btn btn-brand rounded-pill py-2" disabled={busy}>
              {busy ? 'در حال ثبت‌نام...' : 'ثبت‌نام و ورود'}
            </button>
          </div>
        </form>

        <div className="mt-3 small muted text-center">
          حساب دارید؟ <Link to="/login">ورود</Link>
          {' · '}
          <Link to="/">خانه</Link>
        </div>
      </div>
    </div>
  )
}
