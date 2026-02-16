import { Routes, Route } from 'react-router-dom'
import { Navbar } from './components/Navbar'
import { Footer } from './components/Footer'
import { Home } from './pages/Home'
import { Charts } from './pages/Charts'
import { ChartDetail } from './pages/ChartDetail'
import { Docs } from './pages/Docs'
import { Examples } from './pages/Examples'

function App() {
  return (
    <div className="min-h-screen flex flex-col bg-white dark:bg-slate-950">
      <Navbar />
      <main className="flex-1">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/charts" element={<Charts />} />
          <Route path="/charts/:chartId" element={<ChartDetail />} />
          <Route path="/docs" element={<Docs />} />
          <Route path="/docs/*" element={<Docs />} />
          <Route path="/examples" element={<Examples />} />
        </Routes>
      </main>
      <Footer />
    </div>
  )
}

export default App
