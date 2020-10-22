<template>
    <div class="card border-info">
        <div class="card-header">
          <span>You selected chain {{selected_chain}}</span>
          <b-button-close v-on:click="removeItem()" class="btn"></b-button-close>
        </div>
        <div class="level">
            <b-container class="bv-example-row">
            <b-row>
                <b-form-select
                    v-model="selected_chain" :options="chains">Select A Chain
                </b-form-select>
            </b-row>
            <b-row>
                <b-col class="p-0">
                    <b-form-input
                        placeholder="Opacity">
                    </b-form-input>
                </b-col>
                <b-col class="p-0">
                    <b-form-input
                        placeholder="Color">
                    </b-form-input>
                </b-col>
            </b-row>
            </b-container>
        </div>
    </div>
</template>

<script>
export default {
  name: 'attribute-card',
  props: ['chains'],
  data: () => ({
    selected_chain: null,
    opacity: '',
    color: ''
  }),
  mounted: function () {
  },
  methods: {
    removeItem: function () {
      this.$destroy();
      // remove the element from the DOM
      this.$el.parentNode.removeChild(this.$el);
    }
  }
}

</script>

<style scoped>
.card {
    margin-bottom: 20px;
}
.card-header {
    padding: 7px;
    padding-left: 20px;
}
</style>
