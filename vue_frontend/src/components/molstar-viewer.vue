<template>
  <div className="App" id="bruh">
    <div id="viewer3d-controls">
    </div>
    <div id="bruhhh">
      <div id="viewer3d">
      </div>
    </div>
  </div>
</template>
<script>
/* eslint-disable */
import {MolstarDemoViewer} from './mol_viewer';
import 'molstar/build/viewer/molstar.css';

export default {
  name: 'molviewer',
  props: ['pdbFile'],
  data: () => ({
    structure3d : null,
    structure3dRepresentation : 'cartoon',
    structure3dColoring : 'element-symbol',
    uniformColor : {r: 251, g: 158, b: 0},
    viewer : null,
  }),
  mounted: function () {
    let viewer = new MolstarDemoViewer(this.$el.querySelector('#viewer3d'));
  },
  methods: {
    getStructure: function() {
      fetch('data/coordinates.cif')
        .then(function (res) {
          return res.text()
        })
        .then(function (structure) {
          this.structure3d = structure;
        })
        .catch(function (e) {
          console.error(e);
        })
    }
  },
  computed: {
    Viewer3dProps : function () {
      return this.structure3dRepresentation;
    }
  }

}
</script>

<style scoped>
#bruh{
  min-height: 50vh;
}
#bruhhh{
  min-height: 50vh;
}

</style>
