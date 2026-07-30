import { PAGE_SIZE } from '../hooks/useClientPagination'

/**
 * نوار صفحه‌بندی فارسی — ۵۰ رکورد در صفحه
 */
export default function PaginationBar({
  page,
  totalPages,
  total,
  pageSize = PAGE_SIZE,
  from,
  to,
  onChange,
}) {
  if (total <= 0) return null

  const canPrev = page > 1
  const canNext = page < totalPages

  function go(p) {
    const next = Math.min(Math.max(1, p), totalPages)
    if (next !== page) onChange?.(next)
  }

  const windowPages = (() => {
    const maxButtons = 5
    let start = Math.max(1, page - Math.floor(maxButtons / 2))
    let end = Math.min(totalPages, start + maxButtons - 1)
    start = Math.max(1, end - maxButtons + 1)
    const pages = []
    for (let i = start; i <= end; i += 1) pages.push(i)
    return pages
  })()

  return (
    <div className="pagination-bar">
      <div className="pagination-meta muted small">
        نمایش {from} تا {to} از {total}
        {total > pageSize ? ` · صفحه ${page} از ${totalPages}` : ''}
      </div>
      {total > pageSize && (
        <nav className="pagination-nav" aria-label="صفحه‌بندی">
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary rounded-pill"
            disabled={!canPrev}
            onClick={() => go(page - 1)}
          >
            قبلی
          </button>
          {windowPages[0] > 1 && (
            <>
              <button type="button" className="btn btn-sm btn-light rounded-pill" onClick={() => go(1)}>
                1
              </button>
              {windowPages[0] > 2 && <span className="pagination-ellipsis">…</span>}
            </>
          )}
          {windowPages.map((p) => (
            <button
              key={p}
              type="button"
              className={`btn btn-sm rounded-pill ${p === page ? 'btn-brand' : 'btn-light'}`}
              aria-current={p === page ? 'page' : undefined}
              onClick={() => go(p)}
            >
              {p}
            </button>
          ))}
          {windowPages[windowPages.length - 1] < totalPages && (
            <>
              {windowPages[windowPages.length - 1] < totalPages - 1 && (
                <span className="pagination-ellipsis">…</span>
              )}
              <button
                type="button"
                className="btn btn-sm btn-light rounded-pill"
                onClick={() => go(totalPages)}
              >
                {totalPages}
              </button>
            </>
          )}
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary rounded-pill"
            disabled={!canNext}
            onClick={() => go(page + 1)}
          >
            بعدی
          </button>
        </nav>
      )}
    </div>
  )
}
