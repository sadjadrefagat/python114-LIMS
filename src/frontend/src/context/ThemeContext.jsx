import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import { useAuth } from './AuthContext'
import {
  DEFAULT_THEME,
  THEMES,
  applyThemeToDocument,
  isValidTheme,
  normalizeTheme,
  readCachedTheme,
} from '../themes'

const ThemeContext = createContext(null)

// اعمال فوری قبل از رندر برای جلوگیری از چشمک تم
if (typeof document !== 'undefined') {
  applyThemeToDocument(readCachedTheme())
}

export function ThemeProvider({ children }) {
  const { user, isAuthenticated, setUserLocal } = useAuth()
  const [theme, setThemeState] = useState(() => readCachedTheme())
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (isAuthenticated && user?.ui_theme) {
      const next = normalizeTheme(user.ui_theme)
      if (next !== theme) {
        applyThemeToDocument(next)
        setThemeState(next)
      }
      return
    }
    if (!isAuthenticated) {
      const guest = readCachedTheme()
      const next = guest || DEFAULT_THEME
      if (next !== theme) {
        applyThemeToDocument(next)
        setThemeState(next)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, user?.id, user?.ui_theme])

  const value = useMemo(
    () => ({
      theme,
      themes: THEMES,
      saving,
      async setTheme(themeId) {
        if (!isValidTheme(themeId) || themeId === theme) {
          applyThemeToDocument(themeId)
          return
        }
        const prev = theme
        setThemeState(themeId)
        applyThemeToDocument(themeId)
        if (!isAuthenticated) return
        setSaving(true)
        try {
          const data = await api.put('/auth/theme', { ui_theme: themeId })
          if (data?.user && setUserLocal) setUserLocal(data.user)
          else if (data?.ui_theme && setUserLocal && user) {
            setUserLocal({ ...user, ui_theme: data.ui_theme })
          }
        } catch (err) {
          setThemeState(prev)
          applyThemeToDocument(prev)
          throw err
        } finally {
          setSaving(false)
        }
      },
    }),
    [theme, saving, isAuthenticated, user, setUserLocal],
  )

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

export function useTheme() {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error('useTheme باید داخل ThemeProvider باشد')
  return ctx
}
