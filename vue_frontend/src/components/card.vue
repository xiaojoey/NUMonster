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
                    v-model="selected_chain" :options="chains" @change="$emit('update:synced_data', update());" >Select A Chain
                </b-form-select>
            </b-row>
            <b-row>
                <b-col class="p-0">
                    <b-form-input
                        placeholder="Opacity" v-model="opacity" type='number' min="0" max="1" step="0.1" @change="$emit('update:synced_data', update());">
                    </b-form-input>
                </b-col>
                <b-col class="p-0">
                    <b-form-input
                        placeholder="Color" v-model="color" @change="$emit('update:synced_data', update());">
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
  props: ['chains', 'synced_data'],
  data: function () {
    return {
      selected_chain: this.synced_data['chain'],
      opacity: this.synced_data['opacity'],
      color: this.synced_data['color'],
      return_data: this.synced_data,
      render: true,
      surface: null
    }
  },
  mounted: function () {
    this.return_data['render'] = true;
    this.$emit('update:synced_data', this.update());
    // console.log('just added');
  },
  methods: {
    removeItem: function () {
      this.return_data['removed'] = true;
      this.render = false;
      this.$emit('update:synced_data', this.update());
      this.$destroy();
      // remove the element from the DOM
      this.$el.parentNode.removeChild(this.$el);
    },
    update: function () {
      this.return_data['opacity'] = this.opacity;
      this.return_data['color'] = this.color;
      this.return_data['chain'] = this.selected_chain;
      this.return_data['render'] = this.render;
      // console.log(this.return_data);
      if (this.surface != null) {
        this.$parent.removeSurface(this.surface.surfid);
      }
      if (this.render) {
        this.surface = this.$parent.addChainSurface2(this.selected_chain, this.opacity.toString(), this.color);
      }
      return this.return_data;
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
