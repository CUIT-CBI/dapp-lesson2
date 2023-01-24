import Vue from 'vue'
import Router from 'vue-router'

import Main from "../view/Main";
import Search from "../view/Search";
import Wallet from "../view/Wallet";
import Market from "../view/Market";
import Trade from "../view/Trade";
import Create from "../view/create";
import SearchStore from "../view/SearchStore";

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'Main',
      component: Main,
      children:[
        {
          path: '/search',
          component:Search,
        },
        {
          path: '/wallet',
          component:Wallet,
        },
        {
          path: '/market',
          component:Market,
        },
        {
          path: '/trade',
          component:Trade,
        },
        {
          path:'/searchstore',
          component:SearchStore
        }
      ]
    },
    {
      path: '/create',
      component:Create,
    }
  ]
})
