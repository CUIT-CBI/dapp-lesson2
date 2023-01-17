import { createRouter, createWebHashHistory } from 'vue-router'
import HomeView from '../views/Home.vue'
import WelcomeView from '../views/Welcome.vue'
import addLiquidityView from '../components/addLiquidity.vue'
import removeLiquidityView from '../components/removeLiquidity.vue'
import swapView from '../components/swap.vue'
import UserAdminView from '../components/UserAdmin.vue'

const routes = [
  {
    path: '/',
    name: 'home',
    component: HomeView,
    redirect: '/welcome',
    children: [
      { path: '/welcome', component: WelcomeView },
      {
        path: '/factory/add',
        name: 'addLiquidity',
        component: addLiquidityView
      },
      {
        path: '/factory/remove',
        name: 'removeLiquidity',
        component: removeLiquidityView
      },
      {
        path: '/factory/swap',
        name: 'swap',
        component: swapView
      },
      {
        path: '/user/admin',
        name: 'admin',
        component: UserAdminView
      },
    ]
  }

]

const router = createRouter({
  // mode: 'history',
  history: createWebHashHistory(),
  routes
})

export default router
