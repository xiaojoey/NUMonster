<template>
    <div id="inner" class="row card-body">
      <div  class="col-1">
        <div id="viewer3d">
        </div>
      </div>
      <div class="col-2">
        <h5> Option </h5>
        <b-button type='button' class='btn btn-secondary btn-block' v-on:click='toggleVisibility'> Toggle Controls </b-button>
        <b-button type='button' class='btn btn-secondary btn-block' v-on:click='toggleNucleotide'> Toggle Nucleotide </b-button>
        <b-button type='button' class='btn btn-secondary btn-block' v-on:click='toggleStick'> Toggle Sticks </b-button>
        <br/>
        <attribute-card2
          v-for="item in added_cards"
          v-bind:chains="options"
          v-bind:synced_data.sync="item"
          v-bind:key="item.id"
        ></attribute-card2>
      </div>
    </div>
</template>
<script>
/* eslint-disable */
import {MolstarDemoViewer} from './mol_viewer';
import 'molstar/build/viewer/molstar.css';
import attributeCard2 from "./card2";

export default {
  name: 'molviewer',
  components: {
    attributeCard2
  },
  props: ['pdbFile', 'cards'],
  data: () => ({
    structure3d : null,
    structure3dRepresentation : 'cartoon',
    structure3dColoring : 'element-symbol',
    uniformColor : {r: 51, g: 158, b: 0},
    viewer : null,
    added_cards: null,
    controls: null,
    show_nucleotide: true,
    show_stick: false,
  }),
  mounted: function () {
    let viewer = new MolstarDemoViewer(this.$el.querySelector('#viewer3d'));
    this.viewer = viewer;
    this.added_cards = this.cards;
    console.log(this.added_cards);
    this.controls = true;
    viewer.loadStructureFromData(this.pdbFile, 'pdb',
      {type: this.structure3dRepresentation,
        coloring: this.structure3dColoring,
        uniformColor: this.uniformColor});
    fetch(this.pdbFile)
      .then(function (res) {console.log(res)})
      .catch(function (e) {
        console.error(e);
      })
  },
  methods: {
    toggleVisibility: function () {
      this.controls = ! this.controls;
      this.viewer.toggleControls(this.controls);
    },
    toggleNucleotide: function () {
      this.show_nucleotide = ! this.show_nucleotide;
      if (!this.show_nucleotide) {
        this.structure3dRepresentation = 'no_nucleotide';
      } else {
        this.structure3dRepresentation = 'cartoon';
      }
      this.updateModel();
    },
    toggleStick: function () {
      this.show_stick = ! this.show_stick;
      if (this.show_stick) {
        this.structure3dRepresentation = 'ball-and-stick';
      } else {
        this.structure3dRepresentation = 'cartoon';
      }
      this.updateModel();
    },
    updateModel: function () {
      this.viewer.updateMoleculeRepresentation({type: this.structure3dRepresentation,
        coloring: this.structure3dColoring,
        uniformColor: this.uniformColor})
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
#inner {
  min-height: 80vh;
  width: 100%;
  display: flex;
  flex-direction: row;
}
#viewer3d {
  height: 100%;
  width: 100%;
}

.col-1{
  max-width: calc(100% - 250px);
  flex-grow: 1;
  padding: 0px;
  min-height: 80vh;
}
.col-2{
  min-width: 250px;
  height: 80vh;
  padding: 5px;
  flex-direction: column;
}

.card-body {
  padding: 5px;
  margin: 0px;
}
</style>
