import Vue from 'vue'
import Router from 'vue-router'
import Submit from '@/components/Submit'
import Result from '@/components/Result'

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/',
      name: 'Submit',
      component: Submit
    }, {
      path: '/result/:job_id',
      name: 'Result',
      component: Result
    }
  ]
})
