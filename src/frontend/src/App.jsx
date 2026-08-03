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
const Payments = lazy(() => import('./pages/Payments'))
const Languages = lazy(() => import('./pages/Languages'))
const Levels = lazy(() => import('./pages/Levels'))
const Sessions = lazy(() => import('./pages/Sessions'))
const Scores = lazy(() => import('./pages/Scores'))
const PlacementExam = lazy(() => import('./pages/PlacementExam'))
const PlacementBank = lazy(() => import('./pages/PlacementBank'))
const Lookups = lazy(() => import('./pages/Lookups'))
const Users = lazy(() => import('./pages/Users'))
const About = lazy(() => import('./pages/About'))
const Shop = lazy(() => import('./pages/Shop'))
const ShopProduct = lazy(() => import('./pages/ShopProduct'))
const Cart = lazy(() => import('./pages/Cart'))
const ShopAdmin = lazy(() => import('./pages/ShopAdmin'))
const MyCourses = lazy(() => import('./pages/MyCourses'))
const TeacherClasses = lazy(() => import('./pages/TeacherClasses'))
const TeacherCourses = lazy(() => import('./pages/TeacherCourses'))
const TeacherStudents = lazy(() => import('./pages/TeacherStudents'))
const TeacherAttendance = lazy(() => import('./pages/TeacherAttendance'))
const Activities = lazy(() => import('./pages/Activities'))
const NotFound = lazy(() => import('./pages/NotFound'))

const STAFF_ROLES = ['admin', 'secretary', 'education']
const SESSION_ROLES = ['admin', 'secretary', 'education', 'teacher']
const TEACHER_ROLES = ['teacher', 'admin', 'secretary', 'education']
const FINANCE_ROLES = ['admin', 'secretary', 'education', 'finance']

export default function App() {
  const { hasRole } = useAuth()
  const location = useLocation()
  const isStaff = hasRole(...STAFF_ROLES)
  const isTeacher = hasRole('teacher')
  const isFinance = hasRole('finance')
  const showAdminNav = isStaff || isTeacher || (isFinance && !isStaff)
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
    <div className={`app-shell ${showAdminNav ? 'has-admin-sidebar' : ''}`}>
      <Navbar
        showAdminToggle={showAdminNav}
        adminNavOpen={adminNavOpen}
        onToggleAdminNav={() => setAdminNavOpen((v) => !v)}
      />
      <div className="app-body">
        {showAdminNav && (
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
                <Route path="/shop" element={<Shop />} />
                <Route path="/shop/admin" element={
                  <ProtectedRoute roles={STAFF_ROLES}>
                    <ShopAdmin />
                  </ProtectedRoute>
                } />
                <Route path="/shop/:id" element={<ShopProduct />} />
                <Route path="/cart" element={<Cart />} />
                <Route
                  path="/dashboard"
                  element={
                    <ProtectedRoute>
                      <Dashboard />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/placement/bank"
                  element={
                    <ProtectedRoute roles={SESSION_ROLES}>
                      <PlacementBank />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/placement"
                  element={
                    <ProtectedRoute>
                      <PlacementExam />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/my-courses"
                  element={
                    <ProtectedRoute>
                      <MyCourses />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/teacher/classes"
                  element={
                    <ProtectedRoute roles={TEACHER_ROLES}>
                      <TeacherClasses />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/teacher/courses"
                  element={
                    <ProtectedRoute roles={TEACHER_ROLES}>
                      <TeacherCourses />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/teacher/students"
                  element={
                    <ProtectedRoute roles={TEACHER_ROLES}>
                      <TeacherStudents />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/teacher/attendance"
                  element={
                    <ProtectedRoute roles={TEACHER_ROLES}>
                      <TeacherAttendance />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/languages"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Languages />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/levels"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Levels />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/classes"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Classes />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/sessions"
                  element={
                    <ProtectedRoute roles={SESSION_ROLES}>
                      <Sessions />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/scores"
                  element={
                    <ProtectedRoute roles={SESSION_ROLES}>
                      <Scores />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/students"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Students />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/teachers"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Teachers />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/enrollments"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Enrollments />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/payments"
                  element={
                    <ProtectedRoute roles={FINANCE_ROLES}>
                      <Payments />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/lookups"
                  element={
                    <ProtectedRoute roles={STAFF_ROLES}>
                      <Lookups />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/users"
                  element={
                    <ProtectedRoute roles={['admin']}>
                      <Users />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="/activities"
                  element={
                    <ProtectedRoute roles={['admin']}>
                      <Activities />
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
