import { useEffect, useState } from 'react'
import { Navigate, Route, Routes, useLocation } from 'react-router-dom'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import AdminSidebar from './components/AdminSidebar'
import ProtectedRoute from './components/ProtectedRoute'
import { useAuth } from './context/AuthContext'
import Home from './pages/Home'
import Login from './pages/Login'
import Register from './pages/Register'
import Courses from './pages/Courses'
import CourseDetail from './pages/CourseDetail'
import Dashboard from './pages/Dashboard'
import Classes from './pages/Classes'
import Students from './pages/Students'
import Teachers from './pages/Teachers'
import Enrollments from './pages/Enrollments'
import Languages from './pages/Languages'
import Levels from './pages/Levels'
import Sessions from './pages/Sessions'
import Lookups from './pages/Lookups'

export default function App() {
  const { hasRole } = useAuth()
  const location = useLocation()
  const isStaff = hasRole('admin', 'secretary')
  const [adminNavOpen, setAdminNavOpen] = useState(false)

  useEffect(() => {
    setAdminNavOpen(false)
  }, [location.pathname])

  useEffect(() => {
    if (!adminNavOpen) return undefined
    const onKey = (e) => {
      if (e.key === 'Escape') setAdminNavOpen(false)
    }
    document.addEventListener('keydown', onKey)
    document.body.classList.add('admin-nav-lock')
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.classList.remove('admin-nav-lock')
    }
  }, [adminNavOpen])

  return (
    <div className={`app-shell ${isStaff ? 'has-admin-sidebar' : ''}`}>
      <Navbar
        showAdminToggle={isStaff}
        adminNavOpen={adminNavOpen}
        onToggleAdminNav={() => setAdminNavOpen((v) => !v)}
      />
      <div className="app-body">
        {isStaff && (
          <AdminSidebar open={adminNavOpen} onClose={() => setAdminNavOpen(false)} />
        )}
        <div className="app-content">
          <main className="app-main">
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />
              <Route path="/courses" element={<Courses />} />
              <Route path="/courses/:id" element={<CourseDetail />} />
              <Route
                path="/dashboard"
                element={
                  <ProtectedRoute>
                    <Dashboard />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/languages"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Languages />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/levels"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Levels />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/classes"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Classes />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/sessions"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Sessions />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/students"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Students />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/teachers"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Teachers />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/enrollments"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Enrollments />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/lookups"
                element={
                  <ProtectedRoute roles={['admin', 'secretary']}>
                    <Lookups />
                  </ProtectedRoute>
                }
              />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </main>
          <Footer />
        </div>
      </div>
    </div>
  )
}
