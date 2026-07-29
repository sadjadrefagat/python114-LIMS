import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { api, authStorage } from '../api/client'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => authStorage.getStoredUser())
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function boot() {
      const tokens = authStorage.getTokens()
      if (!tokens?.access_token) {
        setLoading(false)
        return
      }
      try {
        const data = await api.get('/auth/me')
        setUser(data.user)
        authStorage.setStoredUser(data.user)
      } catch {
        authStorage.clear()
        setUser(null)
      } finally {
        setLoading(false)
      }
    }
    boot()
  }, [])

  const value = useMemo(
    () => ({
      user,
      loading,
      isAuthenticated: Boolean(user),
      hasRole: (...roles) => {
        if (!user?.role) return false
        if (user.role === 'admin') return true
        return roles.includes(user.role)
      },
      async login(username, password) {
        const data = await api.post(
          '/auth/login',
          { username, password },
          { skipAuth: true },
        )
        authStorage.setTokens({
          access_token: data.access_token,
          refresh_token: data.refresh_token,
        })
        authStorage.setStoredUser(data.user)
        setUser(data.user)
        return data.user
      },
      async register(payload) {
        const data = await api.post('/auth/register', payload, { skipAuth: true })
        authStorage.setTokens({
          access_token: data.access_token,
          refresh_token: data.refresh_token,
        })
        authStorage.setStoredUser(data.user)
        setUser(data.user)
        return data.user
      },
      async logout() {
        const tokens = authStorage.getTokens()
        try {
          if (tokens?.refresh_token) {
            await api.post('/auth/logout', { refresh_token: tokens.refresh_token })
          }
        } catch {
          /* ignore */
        }
        authStorage.clear()
        setUser(null)
      },
    }),
    [user, loading],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth باید داخل AuthProvider باشد')
  return ctx
}
