import { lazy, Suspense, useEffect, useState } from 'react'
import { Route, Routes, useLocation } from 'react-router-dom'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import AdminSidebar from './components/AdminSidebar'
import ProtectedRoute from './components/ProtectedRoute'
import Loading from './components/Loading'
import { useAuth } from './context/AuthContext'

const Home = lazy(() => import('./pages/Home'))
const Login = lazy(() => import('./pages/Login'))
const Register = lazy(() => import('./pages/Register'))
const Courses = lazy(() => import('./pages/Courses'))
const CourseDetail = lazy(() => import('./pages/CourseDetail'))
const Dashboard = lazy(() => import('./pages/Dashboard'))
const Classes = lazy(() => import('./pages/Classes'))
const Students = lazy(() => import('./pages/Students'))
const Teachers = lazy(() => import('./pages/Teachers'))
const Enrollments = lazy(() => import('./pages/Enrollments'))
const Languages = lazy(() => import('./pages/Languages'))
const Levels = lazy(() => import('./pages/Levels'))
const Sessions = lazy(() => import('./pages/Sessions'))
const Lookups = lazy(() => import('./pages/Lookups'))
const About = lazy(() => import('./pages/About'))
const NotFound = lazy(() => import('./pages/NotFound'))

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
            <Suspense fallback={<Loading />}>
              <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/login" element={<Login />} />
                <Route path="/register" element={<Register />} />
                <Route path="/courses" element={<Courses />} />
                <Route path="/courses/:id" element={<CourseDetail />} />
                <Route path="/about" element={<About />} />
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
                <Route path="*" element={<NotFound />} />
              </Routes>
            </Suspense>
          </main>
          <Footer />
        </div>
      </div>
    </div>
  )
}
