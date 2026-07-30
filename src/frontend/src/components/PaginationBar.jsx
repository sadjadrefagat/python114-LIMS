import { PAGE_SIZE } from '../hooks/useClientPagination'

/**
 * حداکثر ۵ شماره صفحه + … برای صفحات خارج از پنجره
 * دکمه‌های اول/آخر جدا هستند و اینجا تکرار نمی‌شوند.
 */
function buildPageItems(page, totalPages) {
  if (totalPages <= 1) return []
  if (totalPages <= 5) {
    return Array.from({ length: totalPages }, (_, i) => i + 1)
  }

  const windowSize = 5
  let start = page - Math.floor(windowSize / 2)
  let end = start + windowSize - 1

  if (start < 1) {
    start = 1
    end = windowSize
  }
  if (end > totalPages) {
    end = totalPages
    start = totalPages - windowSize + 1
  }

  const items = []
  if (start > 1) items.push('…')
  for (let i = start; i <= end; i += 1) items.push(i)
  if (end < totalPages) items.push('…')
  return items
}

/**
 * نوار صفحه‌بندی — اول / قبلی / حداکثر ۵ شماره / بعدی / آخر
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
  const items = buildPageItems(page, totalPages)

  function go(p) {
    const next = Math.min(Math.max(1, p), totalPages)
    if (next !== page) onChange?.(next)
  }

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
            className="btn btn-sm btn-outline-secondary pagination-btn"
            disabled={!canPrev}
            title="اولین صفحه"
            aria-label="اولین صفحه"
            onClick={() => go(1)}
          >
            <i className="bi bi-chevron-double-right" aria-hidden="true" />
          </button>
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary pagination-btn"
            disabled={!canPrev}
            title="صفحه قبل"
            aria-label="صفحه قبل"
            onClick={() => go(page - 1)}
          >
            <i className="bi bi-chevron-right" aria-hidden="true" />
            <span className="pagination-btn-label">قبلی</span>
          </button>

          {items.map((item, idx) =>
            item === '…' ? (
              <span key={`e-${idx}`} className="pagination-ellipsis" aria-hidden="true">
                …
              </span>
            ) : (
              <button
                key={item}
                type="button"
                className={`btn btn-sm pagination-btn ${item === page ? 'btn-brand' : 'btn-light'}`}
                aria-current={item === page ? 'page' : undefined}
                onClick={() => go(item)}
              >
                {item}
              </button>
            ),
          )}

          <button
            type="button"
            className="btn btn-sm btn-outline-secondary pagination-btn"
            disabled={!canNext}
            title="صفحه بعد"
            aria-label="صفحه بعد"
            onClick={() => go(page + 1)}
          >
            <span className="pagination-btn-label">بعدی</span>
            <i className="bi bi-chevron-left" aria-hidden="true" />
          </button>
          <button
            type="button"
            className="btn btn-sm btn-outline-secondary pagination-btn"
            disabled={!canNext}
            title="آخرین صفحه"
            aria-label="آخرین صفحه"
            onClick={() => go(totalPages)}
          >
            <i className="bi bi-chevron-double-left" aria-hidden="true" />
          </button>
        </nav>
      )}
    </div>
  )
}
