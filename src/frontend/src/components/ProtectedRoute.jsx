import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

export default function ProtectedRoute({ children, roles }) {
  const { isAuthenticated, loading, hasRole } = useAuth()
  const location = useLocation()

  if (loading) {
    return (
      <div className="container py-5 text-center muted">
        <div className="spinner-border text-success" role="status" />
        <div className="mt-2">در حال بارگذاری...</div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  if (roles?.length && !hasRole(...roles)) {
    return <Navigate to="/dashboard" replace />
  }

  return children
}
