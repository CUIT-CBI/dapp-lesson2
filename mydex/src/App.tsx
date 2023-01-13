import { useRoutes } from 'react-router-dom';
import routes  from './routes'

function App() {
  const outlet = useRoutes(routes)
  return (
    <>
    {outlet}
    </>
  )
}

export default App
