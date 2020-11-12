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
            <b-row v-if="type === 'model'">
                <b-form-select
                    v-model="model_type" :options="styles" @change="$emit('update:synced_data', update());" >Pick Style
                </b-form-select>
            </b-row>
            <b-row>
                <b-col class="p-0">
                    <b-form-input
                        placeholder="Opacity" v-model.number="opacity" type='number' min="0" max="1" step="0.1" @change="$emit('update:synced_data', update());">
                    </b-form-input>
                </b-col>
                <b-col class="p-0">
                    <b-form-input
                        placeholder="Color" v-model="color" @change="$emit('update:synced_data', update());">
                    </b-form-input>
                </b-col>
            </b-row>
            <b-row v-if="type === 'surface'">
                <b-form-select
                    v-model="color_scheme" :options="color_scheme_options" @change="$emit('update:synced_data', update());" >
                </b-form-select>
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
      color_scheme: this.synced_data['color_scheme'],
      type: this.synced_data['type'],
      model_type: this.synced_data['model_type'],
      return_data: this.synced_data,
      render: true,
      removed: false,
      surface: null,
      styles: [
        {id: 0, value: null, text: 'Select a style'},
        {id: 1, value: 'stick', text: 'stick'},
        {id: 2, value: 'cartoon', text: 'cartoon'},
        {id: 3, value: 'line', text: 'line'}
      ],
      color_scheme_options: []
    }
  },
  mounted: function () {
    // this.return_data['render'] = true;
    // this.$emit('update:synced_data', this.update());
    let color_schemes = ['None'].concat(Object.keys($3Dmol.builtinColorSchemes).concat(['greenCarbon', 'cyanCarbon', // eslint-disable-line
      'yellowCarbon', 'whiteCarbon', 'magentaCarbon']));
    color_schemes.forEach((el, index) => this.color_scheme_options.push({id: index, value: el, text: el}));
    this.$emit('update:synced_data', this.update());
  },
  methods: {
    removeItem: function () {
      this.removed = true;
      this.render = false;
      this.$emit('update:synced_data', this.update());
      this.$destroy();
      // remove the element from the DOM
      this.$el.parentNode.removeChild(this.$el);
    },
    update: function () {
      this.return_data['opacity'] = this.opacity;
      this.return_data['color'] = this.color;
      this.return_data['color_scheme'] = this.color_scheme;
      this.return_data['chain'] = this.selected_chain;
      this.return_data['render'] = this.render;
      this.return_data['model_type'] = this.model_type;
      this.return_data['removed'] = this.removed;
      if (this.surface != null) {
        this.$parent.removeSurface(this.surface.surfid);
      }
      if (this.type === 'surface') {
        if (this.render) {
          this.surface = this.$parent.addChainSurface(this.selected_chain, this.opacity, this.color_scheme, this.color);
        }
      } else if (this.type === 'model') {
        // this.$parent.addModelStyle(this.model_type, this.selected_chain, this.opacity, this.color, this.removed);
        // this.$parent.renderStyles();
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
