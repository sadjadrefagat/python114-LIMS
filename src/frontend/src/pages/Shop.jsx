import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { api, formatMoney, rememberCartSession } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'
import VazirSelect from '../components/VazirSelect'
import PaginationBar from '../components/PaginationBar'
import { useClientPagination } from '../hooks/useClientPagination'

const PRODUCT_TYPES = [
  { value: '', label: 'همه انواع' },
  { value: 'book', label: 'کتاب' },
  { value: 'file', label: 'فایل دیجیتال' },
  { value: 'stationery', label: 'لوازم التحریر' },
  { value: 'course_pack', label: 'پکیج دوره' },
  { value: 'other', label: 'سایر' },
]

const SORT_OPTIONS = [
  { value: '', label: 'پیشنهادی' },
  { value: 'newest', label: 'جدیدترین' },
  { value: 'popular', label: 'محبوب‌ترین' },
  { value: 'price_asc', label: 'ارزان‌ترین' },
  { value: 'price_desc', label: 'گران‌ترین' },
]

const TYPE_ICON = {
  book: 'bi-book',
  file: 'bi-file-earmark-music',
  stationery: 'bi-pencil-square',
  course_pack: 'bi-box-seam',
  other: 'bi-bag',
}

const TYPE_TONE = {
  book: 'tone-teal',
  file: 'tone-sky',
  stationery: 'tone-sun',
  course_pack: 'tone-coral',
  other: 'tone-violet',
}

export default function Shop() {
  const { isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [search, setSearch] = useState(searchParams.get('q') || '')
  const [categoryRef, setCategoryRef] = useState(searchParams.get('cat') || '')
  const [productType, setProductType] = useState(searchParams.get('type') || '')
  const [sort, setSort] = useState(searchParams.get('sort') || '')
  const [tab, setTab] = useState('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busyId, setBusyId] = useState(null)
  const paging = useClientPagination(products)

  useEffect(() => {
    api.get('/shop/categories').then((d) => setCategories(d.categories || [])).catch(() => {})
  }, [])

  useEffect(() => {
    const timer = setTimeout(async () => {
      setLoading(true)
      setError('')
      try {
        if (tab === 'likes' || tab === 'bookmarks') {
          if (!isAuthenticated) {
            setProducts([])
            setError('برای مشاهده این فهرست وارد شوید.')
            return
          }
          const path = tab === 'likes' ? '/shop/me/likes' : '/shop/me/bookmarks'
          const data = await api.get(path)
          setProducts(data.products || [])
        } else {
          const params = new URLSearchParams()
          if (search.trim()) params.set('search', search.trim())
          if (categoryRef) params.set('category_ref', categoryRef)
          if (productType) params.set('product_type', productType)
          if (sort) params.set('sort', sort === 'newest' ? 'newest' : sort)
          const q = params.toString()
          const data = await api.get(`/shop/products${q ? `?${q}` : ''}`)
          setProducts(data.products || [])
        }
        const next = new URLSearchParams()
        if (search.trim()) next.set('q', search.trim())
        if (categoryRef) next.set('cat', categoryRef)
        if (productType) next.set('type', productType)
        if (sort) next.set('sort', sort)
        setSearchParams(next, { replace: true })
      } catch (err) {
        setError(err.message)
        setProducts([])
      } finally {
        setLoading(false)
      }
    }, 250)
    return () => clearTimeout(timer)
  }, [search, categoryRef, productType, sort, tab, isAuthenticated, setSearchParams])

  async function toggleLike(e, product) {
    e.preventDefault()
    e.stopPropagation()
    if (!isAuthenticated) {
      navigate('/login')
      return
    }
    setBusyId(product.Id)
    try {
      const res = await api.post(`/shop/products/${product.Id}/like`)
      setProducts((list) =>
        list
          .map((p) =>
            p.Id === product.Id
              ? { ...p, Liked: res.liked, LikeCount: res.like_count }
              : p,
          )
          .filter((p) => tab !== 'likes' || p.Liked),
      )
    } catch (err) {
      setError(err.message)
    } finally {
      setBusyId(null)
    }
  }

  async function toggleBookmark(e, product) {
    e.preventDefault()
    e.stopPropagation()
    if (!isAuthenticated) {
      navigate('/login')
      return
    }
    setBusyId(product.Id)
    try {
      const res = await api.post(`/shop/products/${product.Id}/bookmark`)
      setProducts((list) =>
        list
          .map((p) => (p.Id === product.Id ? { ...p, Bookmarked: res.bookmarked } : p))
          .filter((p) => tab !== 'bookmarks' || p.Bookmarked),
      )
    } catch (err) {
      setError(err.message)
    } finally {
      setBusyId(null)
    }
  }

  async function addToCart(e, product) {
    e.preventDefault()
    e.stopPropagation()
    setBusyId(product.Id)
    setMessage('')
    try {
      const cart = rememberCartSession(await api.get('/shop/cart'))
      const existing = (cart.items || []).find((i) => i.ProductRef === product.Id)
      const qty = (existing ? Number(existing.Qty) : 0) + 1
      const res = rememberCartSession(
        await api.post('/shop/cart', { product_ref: product.Id, qty }),
      )
      setMessage(res.message || 'به سبد اضافه شد')
      window.dispatchEvent(new Event('lims-cart-changed'))
    } catch (err) {
      setError(err.message)
    } finally {
      setBusyId(null)
    }
  }

  return (
    <div className="container py-4 shop-page">
      <div className="page-head shop-page-head">
        <div>
          <p className="page-kicker">کاتالوگ آموزشگاه</p>
          <h1>فروشگاه اقلام آموزشی</h1>
          <p className="text-muted mb-0">کتاب، فایل، لوازم و پکیج‌های آمادگی آزمون</p>
        </div>
        <div className="shop-page-actions">
          <Link className="btn btn-outline-primary" to="/cart">
            <i className="bi bi-cart3 me-1" />
            سبد خرید
          </Link>
        </div>
      </div>

      <div className="shop-tabs mb-3" role="tablist">
        {[
          { id: 'all', label: 'کاتالوگ', icon: 'bi-grid' },
          { id: 'likes', label: 'پسندیده‌ها', icon: 'bi-heart' },
          { id: 'bookmarks', label: 'نشان‌ها', icon: 'bi-bookmark' },
        ].map((t) => (
          <button
            key={t.id}
            type="button"
            role="tab"
            className={`shop-tab ${tab === t.id ? 'is-active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            <i className={`bi ${t.icon}`} />
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'all' && (
        <div className="shop-filters card border-0 shadow-sm mb-4">
          <div className="card-body">
            <div className="row g-3 align-items-end">
              <div className="col-md-4">
                <label className="form-label">جستجو</label>
                <div className="input-group">
                  <span className="input-group-text">
                    <i className="bi bi-search" />
                  </span>
                  <input
                    className="form-control"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder="نام، کد کالا، توضیحات…"
                  />
                </div>
              </div>
              <div className="col-md-3">
                <label className="form-label">طبقه‌بندی</label>
                <VazirSelect
                  value={categoryRef}
                  onChange={setCategoryRef}
                  options={[
                    { value: '', label: 'همه دسته‌ها' },
                    ...categories.map((c) => ({ value: String(c.Id), label: c.Name })),
                  ]}
                />
              </div>
              <div className="col-md-2">
                <label className="form-label">نوع</label>
                <VazirSelect value={productType} onChange={setProductType} options={PRODUCT_TYPES} />
              </div>
              <div className="col-md-3">
                <label className="form-label">مرتب‌سازی</label>
                <VazirSelect value={sort} onChange={setSort} options={SORT_OPTIONS} />
              </div>
            </div>
            {categories.length > 0 && (
              <div className="shop-cat-chips mt-3">
                <button
                  type="button"
                  className={`shop-chip ${!categoryRef ? 'is-active' : ''}`}
                  onClick={() => setCategoryRef('')}
                >
                  همه
                </button>
                {categories.map((c) => (
                  <button
                    key={c.Id}
                    type="button"
                    className={`shop-chip ${categoryRef === String(c.Id) ? 'is-active' : ''}`}
                    onClick={() => setCategoryRef(String(c.Id))}
                  >
                    {c.Name}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {message && <div className="alert alert-success">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}

      {loading ? (
        <Loading />
      ) : products.length === 0 ? (
        <div className="empty-state text-center py-5 text-muted">
          <i className="bi bi-bag-x display-5 d-block mb-2" />
          موردی یافت نشد.
        </div>
      ) : (
        <>
          <div className="row g-3">
            {paging.slice.map((p) => (
              <div key={p.Id} className="col-sm-6 col-lg-4 col-xl-3">
                <Link
                  to={`/shop/${p.Id}`}
                  className={`shop-card ${TYPE_TONE[p.ProductType] || 'tone-teal'}`}
                >
                  <div className="shop-card-banner">
                    <i className={`bi ${TYPE_ICON[p.ProductType] || 'bi-bag'}`} />
                    {p.IsFeatured ? <span className="shop-card-featured">ویژه</span> : null}
                    <span className="shop-card-type">{p.ProductTypeLabel || p.ProductType}</span>
                  </div>
                  <div className="shop-card-body">
                    {p.CategoryName && <div className="shop-card-cat">{p.CategoryName}</div>}
                    <h3 className="shop-card-title">{p.Name}</h3>
                    <div className="shop-card-price">{formatMoney(p.Price)}</div>
                    <div className="shop-card-meta">
                      <span>
                        <i className="bi bi-box-seam" /> موجودی {p.Stock}
                      </span>
                      <span>
                        <i className="bi bi-heart" /> {p.LikeCount || 0}
                      </span>
                    </div>
                    <div className="shop-card-actions">
                      <button
                        type="button"
                        className={`btn btn-sm ${p.Liked ? 'btn-danger' : 'btn-outline-danger'}`}
                        disabled={busyId === p.Id}
                        onClick={(e) => toggleLike(e, p)}
                        title="پسندیدن"
                      >
                        <i className={`bi ${p.Liked ? 'bi-heart-fill' : 'bi-heart'}`} />
                      </button>
                      <button
                        type="button"
                        className={`btn btn-sm ${p.Bookmarked ? 'btn-warning' : 'btn-outline-warning'}`}
                        disabled={busyId === p.Id}
                        onClick={(e) => toggleBookmark(e, p)}
                        title="نشان‌گذاری"
                      >
                        <i className={`bi ${p.Bookmarked ? 'bi-bookmark-fill' : 'bi-bookmark'}`} />
                      </button>
                      <button
                        type="button"
                        className="btn btn-sm btn-primary flex-grow-1"
                        disabled={busyId === p.Id || !p.Stock}
                        onClick={(e) => addToCart(e, p)}
                      >
                        <i className="bi bi-cart-plus me-1" />
                        سبد
                      </button>
                    </div>
                  </div>
                </Link>
              </div>
            ))}
          </div>
          <PaginationBar
            className="mt-4"
            page={paging.page}
            totalPages={paging.totalPages}
            total={paging.total}
            pageSize={paging.pageSize}
            from={paging.from}
            to={paging.to}
            onChange={paging.setPage}
          />
        </>
      )}
    </div>
  )
}
