import { Home,Pool,SwapPage,Base} from '../pages';
import { Navigate } from 'react-router-dom'

const routes = [
    {
        path : '/',
        element:<Navigate to = "/home"/>
    },
    {
        path: '/',
        element:<Base/>,
        children: [
            {
                path: "/pool",
                element:<Pool />
            },
            {
                path: "/swap",
                element:<SwapPage/>
            },
            {
                path: "/home",
                element:<Home/>
            },
        ]
    }
  
]

export default routes