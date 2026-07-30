import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { api } from '../api/client'
import { useAuth } from '../context/AuthContext'
import JalaliDatePicker, { todayJalaliString } from '../components/JalaliDatePicker'
import VazirSelect from '../components/VazirSelect'
import { isValidMobile, MOBILE_ERROR, MOBILE_HINT, normalizeMobileInput } from '../utils/mobile'

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

function isFocusableField(el) {
  if (!el || el.disabled) return false
  if (el.classList?.contains('vazir-select-required')) return false
  if (el.getAttribute('tabindex') === '-1') return false
  const tag = el.tagName
  if (tag === 'INPUT') {
    const type = (el.type || 'text').toLowerCase()
    if (['hidden', 'submit', 'button', 'reset', 'file'].includes(type)) return false
    return true
  }
  if (tag === 'BUTTON' && el.classList.contains('vazir-select-trigger')) return true
  if (tag === 'BUTTON' && el.type === 'submit') return true
  return false
}

export default function Register() {
  const { register, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const redirectTo = location.state?.from || '/dashboard'
  const [form, setForm] = useState(initialForm)
  const [languages, setLanguages] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const formRef = useRef(null)
  const today = useMemo(() => todayJalaliString(), [])

  useEffect(() => {
    if (isAuthenticated) navigate(redirectTo, { replace: true })
  }, [isAuthenticated, navigate, redirectTo])

  useEffect(() => {
    api
      .get('/languages')
      .then((data) => setLanguages(data.languages || []))
      .catch(() => {})
  }, [])

  function update(field, value) {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  function focusNextField(fromEl) {
    const root = formRef.current
    if (!root) return false
    const fields = [...root.querySelectorAll('input, button')].filter(isFocusableField)
    let current = fromEl
    if (current?.closest?.('.vazir-select')) {
      current = current.closest('.vazir-select').querySelector('.vazir-select-trigger') || current
    }
    const idx = fields.indexOf(current)
    if (idx === -1) return false
    if (idx < fields.length - 1) {
      fields[idx + 1].focus()
      return true
    }
    return false
  }

  function handleFormKeyDown(e) {
    if (e.key !== 'Enter') return
    if (e.target.tagName === 'TEXTAREA') return
    if (e.target.closest?.('.vazir-select-option')) return
    if (e.target.closest?.('.vazir-select-menu')) return

    const isSubmitBtn =
      e.target.type === 'submit' || e.target.closest?.('button[type="submit"]')
    if (isSubmitBtn) return

    e.preventDefault()
    const moved = focusNextField(e.target)
    if (!moved) {
      formRef.current?.requestSubmit()
    }
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
    if (!isValidMobile(form.mobile)) {
      setError(MOBILE_ERROR)
      return
    }
    if (!form.birth_date) {
      setError('تاریخ تولد را انتخاب کنید')
      return
    }
    if (!form.father_name.trim()) {
      setError('نام پدر الزامی است')
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
      navigate(redirectTo, { replace: true })
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

        <form
          ref={formRef}
          onSubmit={handleSubmit}
          onKeyDown={handleFormKeyDown}
          className="row g-3"
        >
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-first-name">
              نام
            </label>
            <input
              id="reg-first-name"
              className="form-control"
              value={form.first_name}
              onChange={(e) => update('first_name', e.target.value)}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-last-name">
              نام خانوادگی
            </label>
            <input
              id="reg-last-name"
              className="form-control"
              value={form.last_name}
              onChange={(e) => update('last_name', e.target.value)}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-father-name">
              نام پدر
            </label>
            <input
              id="reg-father-name"
              className="form-control"
              value={form.father_name}
              onChange={(e) => update('father_name', e.target.value)}
              required
              autoComplete="off"
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-national-code">
              کد ملی
            </label>
            <input
              id="reg-national-code"
              className="form-control"
              value={form.national_code}
              onChange={(e) =>
                update('national_code', e.target.value.replace(/\D/g, '').slice(0, 10))
              }
              inputMode="numeric"
              maxLength={10}
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-mobile">
              موبایل
            </label>
            <input
              id="reg-mobile"
              className="form-control"
              value={form.mobile}
              onChange={(e) => update('mobile', normalizeMobileInput(e.target.value))}
              placeholder="09123456789"
              inputMode="numeric"
              maxLength={11}
              pattern="09[0-9]{9}"
              title={MOBILE_HINT}
              required
            />
            <div className="form-text">{MOBILE_HINT}</div>
          </div>
          <div className="col-md-6">
            <label className="form-label">تاریخ تولد شمسی</label>
            <JalaliDatePicker
              required
              value={form.birth_date}
              onChange={(v) => update('birth_date', v)}
              maxDate={today}
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">جنسیت</label>
            <VazirSelect
              value={form.gender}
              onChange={(v) => update('gender', v)}
              options={[
                { value: '1', label: 'خانم' },
                { value: '2', label: 'آقا' },
              ]}
            />
          </div>
          <div className="col-md-6">
            <label className="form-label">زبان هدف (اختیاری)</label>
            <VazirSelect
              value={form.target_language_ref}
              onChange={(v) => update('target_language_ref', v)}
              placeholder="انتخاب نشده"
              options={languages.map((lang) => ({
                value: String(lang.Id),
                label: lang.Name,
              }))}
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-email">
              ایمیل (اختیاری)
            </label>
            <input
              id="reg-email"
              type="email"
              className="form-control"
              value={form.email}
              onChange={(e) => update('email', e.target.value)}
              placeholder="نیازی به تأیید ندارد"
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-username">
              نام کاربری
            </label>
            <input
              id="reg-username"
              className="form-control"
              value={form.username}
              onChange={(e) => update('username', e.target.value)}
              autoComplete="username"
              required
            />
          </div>
          <div className="col-md-6">
            <label className="form-label" htmlFor="reg-password">
              رمز عبور
            </label>
            <input
              id="reg-password"
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
            <label className="form-label" htmlFor="reg-password-confirm">
              تکرار رمز عبور
            </label>
            <input
              id="reg-password-confirm"
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
            <button type="submit" className="btn btn-brand rounded-pill py-2" disabled={busy}>
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
