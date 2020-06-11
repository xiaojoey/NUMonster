<template>
  <div id="app">
    <div class="content">
        <div class="header">
          <router-link to="/">
            <img id="logo" src="../static/monster_logo.gif"/>
          </router-link>
        </div>
        <router-view/>
        <div class="push"></div>
    </div>
    <b-navbar class="footer">
      <p>
        MONSTER made possible by grants from the National Cancer Institute and Northwestern University
        <br/>
        &copy; 2003-{{getYear()}} Northwestern University
      </p>
    </b-navbar>
  </div>
</template>

<script>
export default {
  name: 'App',
  methods: {
    getYear: function () {
      return new Date().getFullYear()
    }
  }
}
</script>

<style>
  body, html{
    height: 100%;
    margin: 0px;
  }
  #app{
    height: 100%;
  }
  #logo{
    display: block;
    margin-left: auto;
    margin-right: auto;
  }
  .header{
    padding-bottom: 40px;
    padding-top: 40px;
  }
  .content{
    min-height: 100%;
    margin-bottom: -80px;
  }
  .push{
    height: 80px;
  }
</style>
