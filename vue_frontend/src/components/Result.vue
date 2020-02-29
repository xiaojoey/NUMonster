<template>
  <div id='result' class='container main'>
    <div v-if="display_label" class="card">
      <div class="card-header">
        <span>{{display_label}}</span>
        <b-button-close v-on:click="closeDisplay()" class="btn"></b-button-close>
      </div>
      <div v-if="url_3D" class="card-body" id="target-box">
        <div v-if="url_3D" id="container-01" class="mol-container"></div>
        <!-- <iframe :src="url_3D" class="display-container" frameborder="0"></iframe> -->
      </div>
      <div v-if="display_graph" class="row card-body">
        <div  class="col-10">
          <div id="graph-container" class="display-container"></div>
        </div>
        <div class="col-2">
          <br/>
          <div id="color-table">
            <h5>Filter Edges</h5>
            <!--<br/>
            <vue-slider v-model="dist_filter" :max=15 lazy=True @change="renderGraph"></vue-slider>-->
            <div v-for='edge in all_edges' :key='edge.id' @change="renderGraph" class='form-check'>
              <input type='checkbox' v-model='selected_edges' :value='edge.id' class='form-check-input'/>
              <label v-bind:style="{color: edge.color, 'background-color': 'transparent'}" class='form-check-label'>
                {{ edge.name }}
              </label>
            </div>
          </div>
          <br/>
          <h5>Info</h5>
          {{selected_info}}
        </div>
      </div>
    </div>
    <br/>
    <h3>
      Results for {{$route.params.job_id}}
    </h3>
    <table class="table table-striped">
      <thead>
      <tr>
        <th>Model</th>
        <th>Chain 1</th>
        <th>Chain 2</th>
        <th colspan="2">View Results</th>
        <th>PDB</th>
        <th>Results</th>
        <th>Logs</th>
      </tr>
      </thead>
      <tbody v-if="result">
        <template v-for="(chains, model) in result.models">
          <template v-for="(links, chain) in chains">
            <tr :key="model+chain">
              <td>{{model}}</td>
              <td>{{chain.slice(0,1)}}</td>
              <td>{{chain.slice(1,2)}}</td>
              <td><button v-if="links.PDB" class="btn btn-secondary" v-on:click='open2D(links.PDB.PDB, links.parsed_bonds, `${chain.slice(0,1)} and ${chain.slice(1,2)} chains from model ${model}`)'>2D Display</button></td>
              <td><button v-if="links.PDB" class="btn btn-secondary" v-on:click='open3D(links.PDB.PDB, chain.slice(0,1), chain.slice(1,2), `${chain.slice(0,1)} and ${chain.slice(1,2)} chains from model ${model}`)'>3D Display</button></td>
              <td><a v-if="links.PDB" v-bind:href="links.PDB.PDB">PDB File</a></td>
              <td>
                <a target="_blank" v-bind:href="links.Results.XML">XML File</a>
                <br>
                <a target="_blank" v-bind:href="links.Results.TXT">TXT File</a>
              </td>
              <td>
                <a target="_blank" v-if="links.Logs" v-bind:href="links.Logs.MSMS">MSMS</a>
                <br>
                <a target="_blank" v-if="links.Logs" v-bind:href="links.Logs.HBPlus">HBPlus</a>
              </td>
            </tr>
          </template>
        </template>
      </tbody>
    </table>
    <div class="alert alert-danger" v-if="!result">
      Fetching results
    </div>
  </div>
</template>

<script>
import vueSlider from 'vue-slider-component';
import ButtonClose from 'bootstrap-vue';
export default {
  name: 'Result',
  components: {
    ButtonClose,
    vueSlider,
  },
  data: () => ({
    result: '',
    display_label: '',
    display_graph: false,
    url_3D: false,
    selected_edges: [],
    selected_info: '',
    dist_filter: [
      0,
      15
    ],
    all_edges: {
      HYDPHB: {id: 'HYDPHB', name: 'Hydrophobic', color: '#808080'},
      ELCSTA: {id: 'ELCSTA', name: 'Electrostatic', color: '#008800'},
      HYBOND: {id: 'HYBOND', name: 'Hydrogen Bond', color: '#880000'},
      SLTBDG: {id: 'SLTBDG', name: 'Salt Bridge', color: '#6e0088'},
    },
    open_xml: {},
    s: undefined,
  }),
  mounted: function () {
    let mol_js = document.createElement('script');
    mol_js.setAttribute('src', 'http://3Dmol.csb.pitt.edu/build/3Dmol-min.js');
    document.head.appendChild(mol_js);
    this.selected_edges = Object.keys(this.all_edges);
    this.$http.get(this.$server_url + '/results/' + this.$route.params.job_id).then(function (response) {
      this.result = response.body;
    }, function (response) {
      console.error(response);
      alert('File job fetch failed. Check your browser console for details');
    });
  },
  methods: {
    open3D: function (pdb_url, chain1, chain2, label) {
      this.closeDisplay();
      this.display_label = label;
      this.url_3D = `https://3dmol.csb.pitt.edu/viewer.html?url=${pdb_url}
      &select=chain:${chain1}&style=cartoon:color~green
      &select=chain:${chain2}&style=cartoon:color~yellow;stick`;
      setTimeout(() => {
        this.$el.querySelector('#container-01').style.display = 'block';
        this.makeModel(pdb_url, chain1, chain2, label);
      }, 200)
    },
    makeModel: function (pdb_url) {
      $(function () {
        let element = $('#container-01');
        console.log(element);
        let config = {backgroundColor: 'white'};
        let viewer = $3Dmol.createViewer(element, config);  // eslint-disable-line
        let pdbUri = pdb_url;
        jQuery.ajax(pdbUri, {
          success: function (data) {
            let v = viewer;
            v.addModel( data, 'pdb');                        /* load data */ // eslint-disable-line
            v.setStyle({}, {cartoon: {color: 'spectrum'}});  /* style all atoms */// eslint-disable-line
            v.zoomTo();                                      /* set camera */ // eslint-disable-line
            v.render();                                      /* render scene */ // eslint-disable-line
            v.zoom(1.2, 1000);                               /* slight zoom */ // eslint-disable-line
          },
          error: function (hdr, status, err) {
            console.error('Failed to load PDB ' + pdbUri + ': ' + err);
          },
        });
        // viewer.addSphere({ center: {x: 0, y: 0, z: 0}, radius: 1000.0, color: 'green' });
        // viewer.zoomTo();
        // viewer.render();
        // viewer.zoom(0.8, 2000);
        console.log(viewer);
      });
    },
    parsepdb: function (pdb) {
      let residues = [];
      let bonds = [];
      let min_chain_idx = {};
      let offset = 0;
      pdb.split('\n').forEach((line) => {
        let chain;
        let aa;
        let index;
        if (line.slice(0, 4) === 'ATOM') {
          aa = line.substring(17, 21).trim();
          chain = line.substring(21, 22).trim();
          index = line.substring(22, 26).trim();
          if (!min_chain_idx[chain]) {
            min_chain_idx[chain] = parseInt(index);
          }
          let resid = chain + index;
          if (!residues.length || residues[residues.length - 1].id !== resid) {
            if (residues.length && residues[residues.length - 1].id[0] === chain) {
              bonds.push({
                id: bonds.length,
                label: chain + ' backbone',
                source: residues[residues.length - 1].id,
                target: resid,
                color: '#666',
                size: 0.1,
              });
            } else {
              offset = residues.length
            }
            residues.push({
              id: resid,
              label: `${resid}: ${aa}`,
              x: 2 * (parseInt(index) - min_chain_idx[chain]),
              y: offset,
              color: '#666',
              size: 0.1,
            });
          }
        }
      });
      return {'nodes': residues, 'edges': bonds}
    },
    extractParsedXML: function (xml_json, bond_types) {
      let new_nodes = [];
      let new_edges = [];
      let node_ids = new Set();
      JSON.parse(xml_json).BONDS.BOND.forEach((bond, index) => {
        const source = bond.RESIDUE[0].chain._text + bond.RESIDUE[0]._attributes.index;
        const target = bond.RESIDUE[1].chain._text + bond.RESIDUE[1]._attributes.index;
        if (!node_ids.has(source)) {
          new_nodes.push({
            id: source,
            label: `${source}: ${bond.RESIDUE[0].name._text}`,
            x: 2 * new_nodes.length,
            y: 50,
            size: 1,
            color: '#008888',
          });
          node_ids.add(source)
        }
        if (!node_ids.has(target)) {
          new_nodes.push({
            id: target,
            label: `${target}: ${bond.RESIDUE[0].name._text}`,
            x: 3 * new_nodes.length,
            y: 0,
            size: 1,
          });
          node_ids.add(target)
        }
        if (!bond_types.includes(bond.type._text)) { return }
        if (parseFloat(bond.dist._text) < this.dist_filter[0]) { return }
        if (parseFloat(bond.dist._text) > this.dist_filter[1]) { return }
        new_edges.push({
          id: `Bond ${index + 1}`,
          label: this.all_edges[bond.type._text].name,
          size: 1 / parseFloat(bond.dist._text),
          source: source,
          target: target,
          color: this.all_edges[bond.type._text].color,
          type: bond.type._text,
          dist: bond.dist._text,
        })
      });
      return {'nodes': new_nodes, 'edges': new_edges}
    },
    closeDisplay: function () {
      this.display_label = '';
      this.url_3D = false;
      this.display_graph = false;
      this.s = undefined;
    },
    open2D: function (pdbFile, parsed_xml, label) {
      if (this.url_3D !== false) {
        this.$el.querySelector('#container-01').innerHTML = '';
      }
      this.url_3D = false;
      this.display_label = label;
      this.display_graph = true;
      this.open_xml = parsed_xml;
      if (!this.s) {
        // Instantiate sigma, use SetTimeout to give Vue a chance to load the container
        setTimeout(() => {
          this.s = new sigma({ // eslint-disable-line
            renderer: {
              container: document.getElementById('graph-container'),
              type: 'canvas'
            },
            settings: {
              drawLabels: true,
              maxNodeSize: 5,
              minEdgeSize: 0.2,
              maxEdgeSize: 2,
              enableEdgeHovering: true,
              edgeHoverSizeRatio: 2,
              edgeHoverExtremities: true,
              sideMargin: 5,
              singleHover: true,
            }
          });
          this.s.bind('overNode', e => {
            this.selected_info = `${e.data.node.label}`;
          });
          this.s.bind('overEdge', e => {
            const edge = e.data.edge;
            this.selected_info = `ID: ${edge.id} Type: ${edge.label} Distance: ${edge.dist}`
          });
          this.renderGraph();
        }, 100);
      } else {
        this.renderGraph();
      }
    },
    renderGraph: function () {
      if (!this.s) { return }
      let graph = this.extractParsedXML(this.open_xml, this.selected_edges);
      console.log(graph);
      this.s.graph.clear();
      this.s.graph.read(graph);
      this.s.refresh();
    },
  }
}
</script>

<style scoped>
  .display-container {
    height: 70vh;
    width: 100%;
    margin: auto;
  }
  #color-table {
    float: none;
    display: table-cell;
    vertical-align: bottom;
  }
  .container{
    min-width: 100%;
  }
  .mol-container {
    width: 100%;
    height: 70vh;
    position: relative;
  }
</style>
