/** کاتالوگ تم‌های آمادهٔ رابط کاربری */
export const THEMES = [
  {
    id: 'light',
    label: 'روشن کلاسیک',
    group: 'پایه',
    swatch: ['#0f9d8a', '#f5fbf9', '#ff7a59'],
  },
  {
    id: 'dark',
    label: 'دارک',
    group: 'پایه',
    swatch: ['#2dd4bf', '#0f1419', '#fb7185'],
  },
  {
    id: 'midnight',
    label: 'نیمه‌شب',
    group: 'تیره',
    swatch: ['#60a5fa', '#0b1220', '#a78bfa'],
  },
  {
    id: 'ocean',
    label: 'اقیانوس',
    group: 'رنگی',
    swatch: ['#0284c7', '#e0f2fe', '#06b6d4'],
  },
  {
    id: 'forest',
    label: 'جنگلی',
    group: 'رنگی',
    swatch: ['#15803d', '#ecfdf3', '#84cc16'],
  },
  {
    id: 'sunset',
    label: 'غروب',
    group: 'رنگی',
    swatch: ['#ea580c', '#fff7ed', '#f59e0b'],
  },
  {
    id: 'sunny',
    label: 'آفتابی',
    group: 'روشن',
    swatch: ['#ca8a04', '#fffbeb', '#38bdf8'],
  },
  {
    id: 'rose',
    label: 'رز',
    group: 'رنگی',
    swatch: ['#db2777', '#fdf2f8', '#f472b6'],
  },
]

export const DEFAULT_THEME = 'light'
export const THEME_IDS = THEMES.map((t) => t.id)

export function isValidTheme(id) {
  return THEME_IDS.includes(id)
}

/** تم‌های حذف‌شده را به نزدیک‌ترین گزینه نگاشت می‌کند */
export function normalizeTheme(id) {
  if (id === 'sakura' || id === 'lavender') return 'rose'
  return isValidTheme(id) ? id : DEFAULT_THEME
}

export function applyThemeToDocument(themeId) {
  const id = normalizeTheme(themeId)
  document.documentElement.setAttribute('data-theme', id)
  try {
    localStorage.setItem('lims_theme_cache', id)
  } catch {
    /* ignore */
  }
  return id
}

export function readCachedTheme() {
  try {
    const v = localStorage.getItem('lims_theme_cache')
    return normalizeTheme(v)
  } catch {
    return DEFAULT_THEME
  }
}
