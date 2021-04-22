// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue'
import App from './App'
import router from './router'
import 'bootstrap/dist/css/bootstrap.css';
import 'bootstrap-vue/dist/bootstrap-vue.css';
import sigma from 'sigma';

Vue.config.productionTip = false;
Vue.prototype.$server_url = process.env.SERVER_URL || 'http://localhost:9001';
// Assign to global scope to make plugins work
window.sigma = sigma;

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>'
});
