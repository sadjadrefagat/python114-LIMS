import { Navigate, Route, Routes } from 'react-router-dom'
import Navbar from './components/Navbar'
import Footer from './components/Footer'
import ProtectedRoute from './components/ProtectedRoute'
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

export default function App() {
  return (
    <div className="app-shell">
      <Navbar />
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
            path="/classes"
            element={
              <ProtectedRoute roles={['admin', 'secretary']}>
                <Classes />
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
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
      <Footer />
    </div>
  )
}
