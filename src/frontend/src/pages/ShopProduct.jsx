import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { api, formatMoney, rememberCartSession } from '../api/client'
import { useAuth } from '../context/AuthContext'
import Loading from '../components/Loading'

const TYPE_ICON = {
  book: 'bi-book',
  file: 'bi-file-earmark-music',
  stationery: 'bi-pencil-square',
  course_pack: 'bi-box-seam',
  other: 'bi-bag',
}

export default function ShopProduct() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { isAuthenticated } = useAuth()
  const [product, setProduct] = useState(null)
  const [qty, setQty] = useState(1)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function load() {
    setLoading(true)
    try {
      const data = await api.get(`/shop/products/${id}`)
      setProduct(data.product)
      setError('')
    } catch (err) {
      setError(err.message)
      setProduct(null)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [id])

  async function toggleLike() {
    if (!isAuthenticated) {
      navigate('/login')
      return
    }
    setBusy(true)
    try {
      const res = await api.post(`/shop/products/${id}/like`)
      setProduct((p) => ({ ...p, Liked: res.liked, LikeCount: res.like_count }))
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function toggleBookmark() {
    if (!isAuthenticated) {
      navigate('/login')
      return
    }
    setBusy(true)
    try {
      const res = await api.post(`/shop/products/${id}/bookmark`)
      setProduct((p) => ({ ...p, Bookmarked: res.bookmarked }))
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function addToCart() {
    setBusy(true)
    setMessage('')
    try {
      const res = rememberCartSession(
        await api.post('/shop/cart', { product_ref: Number(id), qty: Number(qty) || 1 }),
      )
      setMessage(res.message || 'به سبد اضافه شد')
      window.dispatchEvent(new Event('lims-cart-changed'))
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  if (loading) return <Loading />
  if (!product) {
    return (
      <div className="container py-5">
        <div className="alert alert-danger">{error || 'محصول یافت نشد'}</div>
        <Link to="/shop" className="btn btn-outline-primary">
          بازگشت به فروشگاه
        </Link>
      </div>
    )
  }

  return (
    <div className="container py-4 shop-detail">
      <nav className="shop-breadcrumb mb-3">
        <Link to="/shop">فروشگاه</Link>
        <span>/</span>
        <span>{product.Name}</span>
      </nav>

      {message && <div className="alert alert-success">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}

      <div className="row g-4">
        <div className="col-lg-5">
          <div className="shop-detail-media">
            <i className={`bi ${TYPE_ICON[product.ProductType] || 'bi-bag'}`} />
            {product.IsFeatured ? <span className="shop-card-featured">ویژه</span> : null}
          </div>
        </div>
        <div className="col-lg-7">
          <div className="shop-detail-body">
            {product.CategoryName && (
              <div className="shop-card-cat mb-2">{product.CategoryName}</div>
            )}
            <h1 className="h3 mb-2">{product.Name}</h1>
            <div className="d-flex flex-wrap gap-2 mb-3">
              <span className="badge text-bg-light border">
                {product.ProductTypeLabel || product.ProductType}
              </span>
              {product.Sku && (
                <span className="badge text-bg-light border">کد: {product.Sku}</span>
              )}
              <span className="badge text-bg-light border">موجودی: {product.Stock}</span>
            </div>
            <div className="shop-detail-price mb-3">{formatMoney(product.Price)}</div>
            {product.Description && (
              <p className="text-muted shop-detail-desc">{product.Description}</p>
            )}

            <div className="shop-detail-buy row g-2 align-items-end mb-3">
              <div className="col-auto">
                <label className="form-label">تعداد</label>
                <input
                  type="number"
                  className="form-control"
                  style={{ width: 96 }}
                  min={1}
                  max={product.Stock || 1}
                  value={qty}
                  onChange={(e) => setQty(e.target.value)}
                />
              </div>
              <div className="col">
                <button
                  type="button"
                  className="btn btn-primary w-100"
                  disabled={busy || !product.Stock}
                  onClick={addToCart}
                >
                  <i className="bi bi-cart-plus me-1" />
                  افزودن به سبد
                </button>
              </div>
            </div>

            <div className="d-flex flex-wrap gap-2">
              <button
                type="button"
                className={`btn ${product.Liked ? 'btn-danger' : 'btn-outline-danger'}`}
                disabled={busy}
                onClick={toggleLike}
              >
                <i className={`bi ${product.Liked ? 'bi-heart-fill' : 'bi-heart'} me-1`} />
                پسندیدن ({product.LikeCount || 0})
              </button>
              <button
                type="button"
                className={`btn ${product.Bookmarked ? 'btn-warning' : 'btn-outline-warning'}`}
                disabled={busy}
                onClick={toggleBookmark}
              >
                <i className={`bi ${product.Bookmarked ? 'bi-bookmark-fill' : 'bi-bookmark'} me-1`} />
                نشان‌گذاری
              </button>
              <Link to="/cart" className="btn btn-outline-primary">
                <i className="bi bi-cart3 me-1" />
                مشاهده سبد
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
