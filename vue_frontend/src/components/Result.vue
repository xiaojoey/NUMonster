<template>
  <div id='result' class='container main'>
    <div v-if="display_label" class="card">
      <div class="card-header">
        <span>{{display_label}}</span>
        <b-button-close v-on:click="closeDisplay()" class="btn"></b-button-close>
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
          <div class="more-info">
            {{selected_info}}
          </div>
          <div id="related-info">
            <h6>Related</h6>
          </div>
        </div>
      </div>
    </div>
    <div v-if="url_3D" class="card" id="target-box">
        <div v-if="display_graph" class="row card-body">
          <div  class="col-10">
            <div v-if="url_3D" id="container-01" class="mol-container"></div>
          </div>
          <div class="col-2">
            <br/>
            <div id="more-options">
              <h5>Options</h5>
              <b-button type='button' class='btn btn-secondary btn-block' v-on:click='hideResLabels'> {{draw_labels ? 'Hide Residue Labels' : 'Show Residue Labels'}} </b-button>
              <b-button type='button' class='btn btn-secondary btn-block' v-on:click='savePic'> Save Picture </b-button>
              <br/>
              <h5>Add Surface</h5>
              <div>
                <b-form-select v-model="selected_chain" :options="options">Select A Chain</b-form-select>
                <div class="mt-2">Selected: <strong>{{ selected_chain }}</strong></div>
                <b-button type='button' :disabled='selected_chain === null' class='btn btn-secondary btn-block' v-on:click='addChainSurface'> Add Surface </b-button>
              </div>
            </div>
            <h5 style="padding-top: 10px;">More Options</h5>
            <div id="added-surfaces">
              <attribute-card
                v-for="item in options"
                v-bind:chains="options"
                v-bind:key="item.id"
              ></attribute-card>
            </div>
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
        <th colspan="1">View Results</th>
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
              <td><button v-if="links.PDB" class="btn btn-secondary" v-on:click='open2D(links.PDB.PDB, links.parsed_bonds, `${chain.slice(0,1)} and ${chain.slice(1,2)} chains from model ${model}`, chain.slice(0,1), chain.slice(1,2))'>2D and 3D Display</button></td>
              <!-- <td><button v-if="links.PDB" class="btn btn-secondary" v-on:click='open3D(links.PDB.PDB, chain.slice(0,1), chain.slice(1,2), `${chain.slice(0,1)} and ${chain.slice(1,2)} chains from model ${model}`, links.parsed_bonds)'>3D Display</button></td> -->
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
import attributeCard from './card.vue';
export default {
  name: 'Result',
  components: {
    ButtonClose,
    vueSlider,
    attributeCard
  },
  data: () => ({
    result: '',
    display_label: '',
    display_graph: false,
    url_3D: false,
    res_labels: [],
    draw_labels: true,
    selected_edges: [],
    selected_info: '',
    chain1: '',
    chain2: '',
    viewer: false,
    pdbFile: '',
    options: '',
    selected_chain: null,
    added_surface: [],
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
    amino_acid: {
      ALA: 'A', ARG: 'R', ASN: 'N', ASP: 'D', CYS: 'C', GLN: 'Q', GLU: 'E', // eslint-disable-line
      GLY: 'G', HIS: 'H', ILE: 'I', LEU: 'L', LYS: 'K', MET: 'M', PHE: 'F', // eslint-disable-line
      PRO: 'P', PYL: 'O', SEC: 'U', SER: 'S', THR: 'T', TRP: 'W', TYR: 'Y', // eslint-disable-line
      VAL: 'V',
    },
    open_xml: {},
    s: undefined,
  }),
  mounted: function () {
    let mol_js = document.createElement('script');
    mol_js.setAttribute('src', 'https://3Dmol.csb.pitt.edu/build/3Dmol-min.js');
    document.head.appendChild(mol_js);
    this.selected_edges = Object.keys(this.all_edges);
    this.$http.get(this.$server_url + '/results/' + this.$route.params.job_id).then(function (response) {
      console.log(response);
      // console.log(response.body.models);
      if (jQuery.isEmptyObject(response.body.models)) {
        console.error('Response models are empty objects');
        alert('Job not finished, fetched job does not contain any models');
      } else {
        this.result = response.body;
      }
    }, function (response) {
      console.error(response);
      alert('File job fetch failed. Check your browser console for details');
    });
  },
  methods: {
    open3D: function (pdb_url, chain1, chain2, parsed_xml, _graph) {
      let graph = _graph || this.extractParsedXML(this.open_xml, this.selected_edges);
      let color_chart = this.all_edges;
      let amino_acid = this.amino_acid;
      let element = $('#container-01');
      let config = {backgroundColor: 'white'};
      this.$el.querySelector('#container-01').style.display = 'block';
      if (!this.viewer) {
        this.viewer = $3Dmol.createViewer(element, config); // eslint-disable-line
      }
      let viewer = this.viewer;
      this.makeModel(pdb_url, chain1, chain2, graph, color_chart, amino_acid, viewer);
    },
    makeModel: function (pdb_url, chain1, chain2, graph, color_chart, amino_acid, _viewer) {
      let res_labels = [];
      $(function () {
        let viewer = _viewer;
        viewer.clear();
        let pdbUri = pdb_url;
        jQuery.ajax(pdbUri, {
          success: function (data) {
            let v = viewer;
            v.addModel( data, 'pdb');                        /* load data */ // eslint-disable-line
            v.setStyle({chain: chain1}, {cartoon: {color: 'cyan', opacity: 1}});  /* style all atoms */// eslint-disable-line
            v.setStyle({chain: chain2}, {cartoon: {color: 'pink', opacity: 1}}); // eslint-disable-line
            for (let i = 0; i < graph.nodes.length; i++) {
              let atom = graph.nodes[i].id;
              let atom_chain = atom.substring(0, 1);
              let atom_id = atom.substring(1, atom.length);
              let label = v.addResLabels({resi: atom_id, chain: atom_chain}, {backgroundOpacity: 0.3});
              res_labels.push(([label[0], [atom_id, atom_chain]]));
              if (atom_chain === chain1) {
                v.setStyle({resi: atom_id, chain: atom_chain}, {cartoon: {color: 'cyan', opacity: 1}, stick: {color: 'cyan'}});
                // v.addSphere({center: {resi: atom_id, chain: atom_chain}, radius: 0.5, color: 'green'});
              } else {
                v.setStyle({resi: atom_id, chain: atom_chain}, {cartoon: {color: 'pink', opacity: 1}, stick: {color: 'pink'}});
                // v.addSphere({center: {resi: atom_id, chain: atom_chain}, radius: 0.5, color: 'yellow'});
              }
            }
            for (let i = 0; i < graph.edges.length; i++) {
              let bond = graph.edges[i];
              let source = bond.source;
              let target = bond.target;
              let bond_color = color_chart[bond.type].color;
              v.addCylinder({start: {resi: source.substring(1, source.length), chain: source.substring(0, 1), atom: bond.source_atom}, end: {resi: target.substring(1, target.length), chain: target.substring(0, 1), atom: bond.target_atom}, radius: 0.1, fromCap: 2, toCap: 2, dashed: false, color: bond_color, opacity: 1});
              v.setClickable({resi: source.substring(1, source.length), chain: source.substring(0, 1), atom: bond.source_atom}, true, function (atom, viewer, event, container) {
                if (!atom.label) {
                  atom.label = viewer.addLabel(amino_acid[atom.resn] + ':' + atom.atom, {position: atom, backgroundColor: atom.style.stick.color, backgroundOpacity: 0.5, fontColor: 'black'});
                } else {
                  viewer.removeLabel(atom.label);
                  delete atom.label;
                }
              });
              v.setClickable({resi: target.substring(1, target.length), chain: target.substring(0, 1), atom: bond.target_atom}, true, function (atom, viewer, event, container) {
                if (!atom.label) {
                  atom.label = viewer.addLabel(amino_acid[atom.resn] + ':' + atom.atom, {position: atom, backgroundColor: atom.style.stick.color, backgroundOpacity: 0.5, fontColor: 'black'});
                } else {
                  viewer.removeLabel(atom.label);
                  delete atom.label;
                }
              });
            }
            v.zoomTo();                              /* set camera */  // eslint-disable-line
            v.render();                                      /* render scene */ // eslint-disable-line
            v.zoom(1.5, 1000);                               /* slight zoom */ // eslint-disable-line
          },
          error: function (hdr, status, err) {
            console.error('Failed to load PDB ' + pdbUri + ': ' + err);
          },
        });
        // console.log(viewer);
      });
      this.res_labels = res_labels;
      this.draw_labels = true;
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
      let node_indices = [];
      JSON.parse(xml_json).BONDS.BOND.forEach((bond, index) => {
        if (!bond_types.includes(bond.type._text)) { return }
        var target = 0;
        var target_atom = 0;
        var source_residue = 0;
        var target_residue = 0;
        var source = 0;
        var source_atom = 0;
        var source_index = 0;

        var target_index = 0;
        if (bond.RESIDUE[0].chain._text === this.chain1) {
          source_index = bond.RESIDUE[0]._attributes.index;
          target_index = bond.RESIDUE[1]._attributes.index;
          source = bond.RESIDUE[0].chain._text + source_index;
          source_atom = bond.RESIDUE[0].atom._text;
          target = bond.RESIDUE[1].chain._text + target_index;
          target_atom = bond.RESIDUE[1].atom._text;
          source_residue = bond.RESIDUE[0].name._text;
          target_residue = bond.RESIDUE[1].name._text;
        } else {
          source_index = bond.RESIDUE[1]._attributes.index;
          target_index = bond.RESIDUE[0]._attributes.index;
          source = bond.RESIDUE[1].chain._text + source_index;
          source_atom = bond.RESIDUE[1].atom._text;
          target = bond.RESIDUE[0].chain._text + target_index;
          target_atom = bond.RESIDUE[0].atom._text;
          source_residue = bond.RESIDUE[1].name._text;
          target_residue = bond.RESIDUE[0].name._text;
        }
        if (!node_ids.has(source)) {
          if (!node_indices.includes(source_index)) {
            node_indices.push(source_index);
          }
          new_nodes.push({
            id: source,
            label: `${source}: ${source_residue}`,
            x: 0,
            y: 0,
            size: 1,
            color: 'cyan',
            index: source_index,
            direction: 'up',
            sigma_label: `${this.amino_acid[source_residue]}${source.substr(1)} ${source.charAt(0)}`,
          });
          node_ids.add(source)
        }
        if (!node_ids.has(target)) {
          if (!node_indices.includes(target_index)) {
            node_indices.push(target_index);
          }
          new_nodes.push({
            id: target,
            label: `${target}: ${target_residue}`,
            x: 0,
            y: 40,
            size: 1,
            color: 'pink',
            index: target_index,
            direction: 'down',
            sigma_label: `${this.amino_acid[target_residue]}${target.substr(1)} ${target.charAt(0)}`,
          });
          node_ids.add(target)
        }

        if (parseFloat(bond.dist._text) < this.dist_filter[0]) { return }
        if (parseFloat(bond.dist._text) > this.dist_filter[1]) { return }
        new_edges.push({
          id: `Bond ${index + 1}`,
          label: this.all_edges[bond.type._text].name,
          size: 1 / parseFloat(bond.dist._text),
          source: source,
          source_atom: source_atom,
          source_label: `${this.amino_acid[source_residue]}${source.substr(1)}.${source.charAt(0)}`,
          target: target,
          target_label: `${this.amino_acid[target_residue]}${target.substr(1)}.${target.charAt(0)}`,
          target_atom: target_atom,
          color: this.all_edges[bond.type._text].color,
          type: bond.type._text,
          dist: bond.dist._text,
          added: [],
        })
      });
      node_indices.sort((a, b) => a - b);
      for (const node of new_nodes) {
        node.x = 5 * node_indices.indexOf(node.index);
      }
      return {'nodes': new_nodes, 'edges': new_edges}
    },
    closeDisplay: function () {
      // this.display_label = '';
      this.url_3D = false;
      // this.display_graph = false;
      this.s = undefined;
    },
    open2D: function (pdbFile, parsed_xml, label, chain1, chain2) {
      this.chain1 = chain1;
      this.chain2 = chain2;
      this.options = [
        { id: 0, value: null, text: 'Select a chain' },
        { id: 1, value: chain1, text: 'Chain ' + chain1 },
        { id: 2, value: chain2, text: 'Chain ' + chain2 }];
      this.display_label = label;
      this.display_graph = true;
      this.open_xml = parsed_xml;
      this.pdbFile = pdbFile;
      this.url_3D = `https://3dmol.csb.pitt.edu/viewer.html?url=${pdbFile}
      &select=chain:${chain1}&style=cartoon:color~green
      &select=chain:${chain2}&style=cartoon:color~yellow;stick`;
      if (this.viewer) {
        this.viewer.clear();
      }
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
              labelAlignment: 'top',
              defaultLabelAlignment: 'top',
              labelThreshold: 0
            }
          });
          this.s.bind('overNode', e => {
            this.selected_info = `${e.data.node.label}`;
            this.$el.querySelector('#related-info').innerHTML = '';
          });
          this.s.bind('overEdge', e => {
            const edge = e.data.edge;
            this.$el.querySelector('#related-info').innerHTML = '<h5>Interactions</h5>';
            let currentBond = `<span style="color:${edge.color}">${edge.source_label}:${edge.source_atom}<>${edge.target_label}:${edge.target_atom}</span>`;
            this.$el.querySelector('#related-info').innerHTML += currentBond + '<br>';
            for (const id of edge.added) {
              let related_edge = this.s.renderers[0].edgesOnScreen.find(x => x.id === id);
              let related_info = `<span style="color:${related_edge.color}">${related_edge.source_label}:${related_edge.source_atom}<>${related_edge.target_label}:${related_edge.target_atom}</span>`;
              this.$el.querySelector('#related-info').innerHTML += related_info + '<br>';
            }
            this.selected_info = `ID: ${edge.id} Type: ${edge.label} Distance: ${edge.dist}`;
          });
          this.s.settings({
            drawLabels: true,
            // labelThreshold: 0
          });
          this.renderGraph();
        }, 100);
      } else {
        this.renderGraph();
      }
      // this.open3D(pdbFile, chain1, chain2, parsed_xml);
    },
    renderGraph: function () {
      // console.log('starting render');
      if (!this.s) { return }
      let graph = this.extractParsedXML(this.open_xml, this.selected_edges);
      for (let i = 0; i < graph.edges.length; i++) {
        let bond = graph.edges[i];
        let id1 = bond.id;
        let source = bond.source;
        let target = bond.target;
        for (let x = 0; x < graph.edges.length; x++) {
          let bond2 = graph.edges[x];
          let id2 = bond2.id;
          let source2 = bond2.source;
          let target2 = bond2.target;
          if (id2 !== id1 && (((source === source2) && (target === target2)) || ((source === target2) && (target === source2)))) {
            if (!bond.added.includes(id2)) {
              bond.added.push(id2);
              bond2.added.push(id1);
            }
          }
        }
      }
      this.s.graph.clear();
      this.s.graph.read(graph);
      this.s.refresh();
      // console.log(this.display_graph);
      this.open3D(this.pdbFile, this.chain1, this.chain2, this.open_xml, graph);
    },
    savePic: function () {
      if (confirm('Save image of 3D model?')) {
        var filename = '3dmol.png';
        var text = this.viewer.pngURI();
        var ImgData = text;
        var link = document.createElement('a');
        link.href = ImgData;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }
    },
    hideResLabels: function () {
      if (this.draw_labels) {
        for (const label of this.res_labels) {
          this.viewer.removeLabel(label[0]);
        }
        this.draw_labels = false;
      } else {
        let new_res_labels = [];
        for (const label of this.res_labels) {
          let new_label = this.viewer.addResLabels({resi: label[1][0], chain: label[1][1]}, {backgroundOpacity: 0.3});
          new_res_labels.push(([new_label[0], label[1]]));
        }
        this.draw_labels = true;
        this.res_labels = new_res_labels;
      }
    },
    addChainSurface: function () {
      if (this.selected_chain != null) {
        this.viewer.addSurface($3Dmol.SurfaceType.VDW, {opacity: 0.8, colorscheme: 'greenCarbon'}, {chain: this.selected_chain}, this.addSurfaceTag()); // eslint-disable-line
      }
    },
    addSurfaceTag: function () {
      alert('hi');
    }
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
    /* display: block; */
    vertical-align: bottom;
  }
  .container{
    min-width: 97%;
  }
  .col-10{
    max-width: calc(100% - 250px);
    padding: 0px;
  }
  .col-2{
    min-width: 250px;
    max-height: 100%;
    display: flex;
    flex-direction: column;
  }
  .mol-container {
    width: 100%;
    height: 100%;
    position: relative;
  }
  #target-box{
    margin-top: 30px;
  }
  .card-body {
    padding: 5px;
    margin: 0px;
  }
  .card {
    display: block;
  }
  #undefined {
    max-width: 100%;
  }
  .more-info, #related-info, #added-surfaces {
    overflow-y: scroll;
    min-width: 100%;
    scrollbar-width: none;
    -ms-overflow-style: none;
  }
  .more-info {
    max-height: 15%;
  }
  .more-info::-webkit-scrollbar, #more-options::-webkit-scrollbar, #related-info::-webkit-scrollbar, #added-surfaces::-webkit-scrollbar{ /* WebKit */
    width: 0;
    height: 0;
  }
  #related-info {
    max-height: 45%;
  }
</style>
