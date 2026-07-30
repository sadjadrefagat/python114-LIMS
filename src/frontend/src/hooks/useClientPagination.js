import { useEffect, useMemo, useState } from 'react'

export const PAGE_SIZE = 50

/**
 * صفحه‌بندی سمت کلاینت — ۵۰ رکورد در هر صفحه
 */
export function useClientPagination(items, pageSize = PAGE_SIZE) {
  const [page, setPage] = useState(1)
  const list = Array.isArray(items) ? items : []
  const total = list.length
  const totalPages = Math.max(1, Math.ceil(total / pageSize) || 1)

  useEffect(() => {
    setPage(1)
  }, [total, pageSize])

  useEffect(() => {
    if (page > totalPages) setPage(totalPages)
  }, [page, totalPages])

  const slice = useMemo(() => {
    const start = (page - 1) * pageSize
    return list.slice(start, start + pageSize)
  }, [list, page, pageSize])

  return {
    page,
    setPage,
    pageSize,
    total,
    totalPages,
    slice,
    from: total === 0 ? 0 : (page - 1) * pageSize + 1,
    to: Math.min(page * pageSize, total),
  }
}
