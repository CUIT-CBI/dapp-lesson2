import Vue from 'vue';
import App from './App';

import router from "./router";

import ElementUI from 'element-ui';
import 'element-ui/lib/theme-chalk/index.css';

import axios from 'axios'
import VueAxios from 'vue-axios'

Vue.use(router);

Vue.use(ElementUI);

Vue.use(VueAxios, axios)

Vue.config.productionTip = false

new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>',
  render:h => h(App) //ElementUI
})
