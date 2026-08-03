const API_BASE = import.meta.env.VITE_API_BASE || '/api'

function getTokens() {
  try {
    return JSON.parse(localStorage.getItem('lims_tokens') || 'null')
  } catch {
    return null
  }
}

function setTokens(tokens) {
  if (!tokens) localStorage.removeItem('lims_tokens')
  else localStorage.setItem('lims_tokens', JSON.stringify(tokens))
}

function getStoredUser() {
  try {
    return JSON.parse(localStorage.getItem('lims_user') || 'null')
  } catch {
    return null
  }
}

function setStoredUser(user) {
  if (!user) localStorage.removeItem('lims_user')
  else localStorage.setItem('lims_user', JSON.stringify(user))
}

const CART_SESSION_KEY = 'lims_cart_session'

export function getCartSession() {
  try {
    return localStorage.getItem(CART_SESSION_KEY) || ''
  } catch {
    return ''
  }
}

export function setCartSession(key) {
  try {
    if (!key) localStorage.removeItem(CART_SESSION_KEY)
    else localStorage.setItem(CART_SESSION_KEY, key)
  } catch {
    /* ignore */
  }
}

export function rememberCartSession(data) {
  if (data?.session_key) setCartSession(data.session_key)
  return data
}

async function request(path, options = {}) {
  const tokens = getTokens()
  const headers = {
    Accept: 'application/json',
    ...(options.body ? { 'Content-Type': 'application/json' } : {}),
    ...(options.headers || {}),
  }

  if (tokens?.access_token && !options.skipAuth) {
    headers.Authorization = `Bearer ${tokens.access_token}`
  }

  const cartSession = getCartSession()
  if (cartSession && !headers['X-Cart-Session']) {
    headers['X-Cart-Session'] = cartSession
  }

  let response
  try {
    response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined,
    })
  } catch (err) {
    const error = new Error('ارتباط با سرور برقرار نشد. مطمئن شوید بک‌اند روی پورت ۸۰۰۰ اجراست.')
    error.status = 0
    error.cause = err
    throw error
  }

  let data = null
  const text = await response.text()
  if (text) {
    try {
      data = JSON.parse(text)
    } catch {
      data = { detail: text }
    }
  }

  if (!response.ok) {
    if (response.status === 405) {
      const error = new Error(
        'متد مجاز نیست — احتمالاً سرور بک‌اند قدیمی است. بک‌اند را ری‌استارت کنید (uvicorn).',
      )
      error.status = 405
      error.data = data
      throw error
    }
    const detail = data?.detail
    let message
    if (Array.isArray(detail)) {
      message = detail
        .map((d) => {
          const raw = d.msg || d.message || JSON.stringify(d)
          return String(raw)
            .replace(/^Value error,\s*/i, '')
            .replace(/^Assertion failed,\s*/i, '')
        })
        .filter(Boolean)
        .join('، ')
    } else if (typeof detail === 'string' && detail.trim()) {
      message = detail
    } else if (typeof data?.message === 'string' && data.message.trim()) {
      message = data.message
    } else if (response.status === 502 || response.status === 503 || response.status === 504) {
      message = 'سرور در دسترس نیست. چند لحظه بعد دوباره تلاش کنید.'
    } else if (response.status === 404) {
      message = 'آدرس API پیدا نشد — احتمالاً بک‌اند قدیمی است؛ uvicorn را ری‌استارت کنید.'
    } else {
      message = `خطایی رخ داد (کد ${response.status})`
    }
    // اگر هنوز پیام انگلیسی خام ماند، پیام کلی فارسی
    if (/^not\s*found$/i.test(message.trim())) {
      message = 'آدرس API پیدا نشد — بک‌اند را از پوشه src/backend ری‌استارت کنید.'
    }
    if (/string does not match|string_type|field required|value is not/i.test(message)) {
      message = data?.message || 'داده ارسالی نامعتبر است'
    }
    const error = new Error(message)
    error.status = response.status
    error.data = data
    throw error
  }

  return data
}

export const api = {
  get: (path, options) => request(path, { ...options, method: 'GET' }),
  post: (path, body, options) => request(path, { ...options, method: 'POST', body }),
  put: (path, body, options) => request(path, { ...options, method: 'PUT', body }),
  delete: (path, options) => request(path, { ...options, method: 'DELETE' }),
  async upload(path, formData, options = {}) {
    const tokens = getTokens()
    const headers = {
      Accept: 'application/json',
      ...(options.headers || {}),
    }
    if (tokens?.access_token && !options.skipAuth) {
      headers.Authorization = `Bearer ${tokens.access_token}`
    }
    const response = await fetch(`${API_BASE}${path}`, {
      method: options.method || 'POST',
      headers,
      body: formData,
    })
    let data = null
    const text = await response.text()
    if (text) {
      try {
        data = JSON.parse(text)
      } catch {
        data = { detail: text }
      }
    }
    if (!response.ok) {
      const detail = data?.detail
      const message =
        typeof detail === 'string'
          ? detail
          : data?.message || 'خطایی در بارگذاری فایل رخ داد'
      const error = new Error(message)
      error.status = response.status
      error.data = data
      throw error
    }
    return data
  },
}

export const authStorage = {
  getTokens,
  setTokens,
  getStoredUser,
  setStoredUser,
  clear() {
    setTokens(null)
    setStoredUser(null)
  },
}

export function formatMoney(value) {
  if (value == null) return '—'
  return Number(value).toLocaleString('en-US') + ' ریال'
}

export function roleLabel(role) {
  const map = {
    admin: 'مدیر',
    secretary: 'منشی',
    education: 'مسئول آموزش',
    finance: 'مالی',
    teacher: 'مدرس',
    student: 'زبان‌آموز',
    parent: 'والدین',
  }
  return map[role] || role || '—'
}
