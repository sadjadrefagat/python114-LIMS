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

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
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
    } else if (typeof detail === 'string') {
      message = detail
    } else {
      message = data?.message || 'خطایی رخ داد'
    }
    // اگر هنوز پیام انگلیسی خام ماند، پیام کلی فارسی
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
  return Number(value).toLocaleString('fa-IR') + ' ریال'
}

export function roleLabel(role) {
  const map = {
    admin: 'مدیر',
    secretary: 'منشی',
    finance: 'مالی',
    teacher: 'مدرس',
    student: 'زبان‌آموز',
    parent: 'والدین',
  }
  return map[role] || role || '—'
}
