import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api, formatMoney, rememberCartSession } from '../api/client'
import Loading from '../components/Loading'

export default function Cart() {
  const [items, setItems] = useState([])
  const [total, setTotal] = useState(0)
  const [count, setCount] = useState(0)
  const [note, setNote] = useState('')
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [orderId, setOrderId] = useState(null)

  async function load() {
    setLoading(true)
    try {
      const data = rememberCartSession(await api.get('/shop/cart'))
      setItems(data.items || [])
      setTotal(data.total || 0)
      setCount(data.count || 0)
      setError('')
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  async function updateQty(productRef, qty) {
    setBusy(true)
    setError('')
    try {
      rememberCartSession(await api.post('/shop/cart', { product_ref: productRef, qty }))
      await load()
      window.dispatchEvent(new Event('lims-cart-changed'))
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function clearCart() {
    setBusy(true)
    try {
      await api.delete('/shop/cart')
      await load()
      window.dispatchEvent(new Event('lims-cart-changed'))
      setMessage('سبد خالی شد')
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  async function checkout() {
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const res = await api.post('/shop/checkout', { note: note.trim() || null })
      setOrderId(res.order_id)
      setMessage(res.message || 'سفارش ثبت شد')
      setItems([])
      setTotal(0)
      setCount(0)
      window.dispatchEvent(new Event('lims-cart-changed'))
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  if (loading) return <Loading />

  return (
    <div className="container py-4 shop-cart-page">
      <div className="page-head">
        <div>
          <p className="page-kicker">فروشگاه</p>
          <h1>سبد خرید</h1>
          <p className="text-muted mb-0">{count} قلم · مجموع {formatMoney(total)}</p>
        </div>
        <Link to="/shop" className="btn btn-outline-primary">
          ادامه خرید
        </Link>
      </div>

      {message && <div className="alert alert-success">{message}</div>}
      {error && <div className="alert alert-danger">{error}</div>}
      {orderId && (
        <div className="alert alert-info">
          شماره سفارش: <strong>{orderId}</strong> — وضعیت: در انتظار تأیید آموزشگاه
        </div>
      )}

      {items.length === 0 ? (
        <div className="empty-state text-center py-5 text-muted">
          <i className="bi bi-cart-x display-5 d-block mb-2" />
          سبد خرید خالی است.
          <div className="mt-3">
            <Link to="/shop" className="btn btn-primary">
              رفتن به فروشگاه
            </Link>
          </div>
        </div>
      ) : (
        <div className="row g-4">
          <div className="col-lg-8">
            <div className="table-responsive card border-0 shadow-sm">
              <table className="table align-middle mb-0">
                <thead>
                  <tr>
                    <th>محصول</th>
                    <th>قیمت</th>
                    <th style={{ width: 140 }}>تعداد</th>
                    <th>جمع</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {items.map((item) => (
                    <tr key={item.Id}>
                      <td>
                        <Link to={`/shop/${item.ProductRef}`} className="fw-semibold text-decoration-none">
                          {item.Name}
                        </Link>
                        {item.Sku && <div className="small text-muted">{item.Sku}</div>}
                      </td>
                      <td>{formatMoney(item.Price)}</td>
                      <td>
                        <input
                          type="number"
                          className="form-control form-control-sm"
                          min={0}
                          max={item.Stock}
                          value={item.Qty}
                          disabled={busy}
                          onChange={(e) => updateQty(item.ProductRef, Number(e.target.value))}
                        />
                      </td>
                      <td>{formatMoney(item.Price * item.Qty)}</td>
                      <td>
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-danger"
                          disabled={busy}
                          onClick={() => updateQty(item.ProductRef, 0)}
                          title="حذف"
                        >
                          <i className="bi bi-trash" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <button
              type="button"
              className="btn btn-link text-danger mt-2 px-0"
              disabled={busy}
              onClick={clearCart}
            >
              خالی کردن سبد
            </button>
          </div>
          <div className="col-lg-4">
            <div className="card border-0 shadow-sm shop-checkout-card">
              <div className="card-body">
                <h2 className="h5 mb-3">ثبت سفارش</h2>
                <div className="d-flex justify-content-between mb-2">
                  <span>تعداد اقلام</span>
                  <strong>{count}</strong>
                </div>
                <div className="d-flex justify-content-between mb-3">
                  <span>مبلغ قابل پرداخت</span>
                  <strong>{formatMoney(total)}</strong>
                </div>
                <label className="form-label">یادداشت (اختیاری)</label>
                <textarea
                  className="form-control mb-3"
                  rows={3}
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="مثلاً تحویل در آموزشگاه شعبه…"
                />
                <button
                  type="button"
                  className="btn btn-primary w-100"
                  disabled={busy}
                  onClick={checkout}
                >
                  ثبت سفارش
                </button>
                <p className="small text-muted mt-2 mb-0">
                  پس از ثبت، سفارش توسط آموزشگاه بررسی و برای تحویل/پرداخت هماهنگ می‌شود.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
