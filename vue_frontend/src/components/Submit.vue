<template>
  <div id='submit' class='container main'>
    <b-alert variant="success"
             dismissible
             :show="showSuccessAlert"
             @dismissed="showSuccessAlert=false">
      Job submission succeeded. Check your email for details
    </b-alert>
    <b-alert variant="danger"
             dismissible
             :show="showFailAlert"
             @dismissed="showFailAlert=false">
      Job submission failed. Check your browser console for details
    </b-alert>
    <div class='row'>
      <!-- COL 1 -->
      <div class='col-sm'>
        <div class='card'>
          <div class='card-header'>
            <h3>File Upload/Enter PDB ID</h3>
          </div>
          <div class='card-body'>
            <div class='form-group' :class='{"has-error": errors.has("email")}' >
              <label class='control-label' for='email' v-b-tooltip.hover.right
                     title='Your job ID will be emailed to you immediately after job submission and
                   you will receive results here when the job is complete'>Email</label>
              <input id='email' v-model='email' v-validate='"required|email"' class='form-control'
                     type='email' name='email'>
              <p class='text-danger' >{{ errors.first('email') }}</p>
            </div>
            <div class='form-group'>
              <label class='control-label' for='file' v-b-tooltip.hover.right
                     title='Upload a local file in .pdb format for analysis'>PDB File</label>
              <input id='file' class='form-control' type='file' ref='file'
                     v-on:change='handleFileUpload'>
            </div>
            <strong>OR</strong>
            <div class='form-group'>
              <label class='control-label' for='pdb_id' v-b-tooltip.hover.right
                     title='Enter the 4 character PDB ID to load directly from the Protein Data
                    Bank'>PDB ID</label>
              <input id='pdb_id' v-model="pdb_id" v-validate='{regex: /[A-Za-z0-9]{4}/ }' class='form-control'
                     type='pdb_id' name='pdb_id'>
              <p class='text-danger' >{{ errors.first('pdb_id') }}</p>
            </div>
            <button type='button' class='btn btn-primary btn-block' v-on:click='parseText'
                    :disabled='!file && !pdb_id'>Next</button>
          </div>
        </div>
      </div>

      <!-- COL 2 -->
      <div class='col-sm'>
        <div class='card' v-if='!all_chains.length'>
          <div class='card-header alert-danger'>
            Upload a PDB file to continue
          </div>
        </div>
        <div id='accordion' v-if='all_chains.length'>
          <div class='card'>
            <div class='card-header' id='chains'>
              <h5 class='mb-0'>
                Chains
              </h5>
            </div>
            <div id='collapseOne' class='collapse show' aria-labelledby='chains'>
              <div class='card-body'>
                <button class='btn btn-sm btn-secondary' v-on:click='selectAllChains'>
                  Select all
                </button>
                <div v-for='chain in all_chains' :key='chain.name' class='form-check'>
                  <input type='checkbox' v-model='selected_chains' :value='chain'
                         class='form-check-input'/>
                  <label class='form-check-label'>
                    {{ chain.name }}: {{chain.start }}-{{chain.end }}
                  </label>
                </div>
              </div>
            </div>
          </div>
          <div class='card'>
            <div class='card-header'>
              <h5 class='mb-0'>
                Select Chain Pairs
              </h5>
            </div>
            <div>
              <div class='card-body'>
                <div class='alert alert-warning' role='alert' v-if='selected_chains.length < 2'>
                  Select at least 2 protein chains to continue
                </div>
                <button class='btn btn-sm btn-secondary' v-on:click='selectAllPairs'
                        v-if='selected_chains.length >= 2'> Select all</button>
                <div v-for='pair in all_pairs' :key="pair" class='form-check'>
                  <input type='checkbox' v-model='selected_pairs' :value='pair'
                         class='form-check-input'/>
                  <label class='form-check-label'>{{pair}}</label>
                </div>
                <br>
                <img v-if="loading" width="50px" src="../../static/loading-gif-transparent-2.gif"/>
                <button v-if="!loading" type='button' class='btn btn-primary w-100' v-on:click='submitJob'
                        :disabled='!(selected_pairs.length && email)'>Analyze</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- COL 3 -->
      <div class='col-sm'>
        <div class='card'>
          <div class='card-header'>
            <h3>Retrieve a result</h3>
          </div>
          <div class='card-body'>
            <div class='form-group'>
              <label class='control-label' for='Job ID' v-b-tooltip.hover.right
                     title='Enter the 10 character Job ID you received at the time of job
                      submission to retrieve the results'>
                Job ID
              </label>
              <input id='Job ID' class='form-control' type='text' v-model='job_id'>
            </div>
            <strong>OR</strong>
            <div class='form-group'>
              <label class='control-label' for='ret_pdb_id' v-b-tooltip.hover.right
                     title='Enter the 4 character PDB ID to load precalculated MONSTER results'>
                PDB ID
              </label>
              <input id='ret_pdb_id' v-model='ret_pdb_id' v-validate='{regex: /[A-Z0-9]{4}/ }'
                     class='form-control' type='ret_pdb_id' name='ret_pdb_id' disabled>
              <p class='text-danger' >{{ errors.first('ret_pdb_id') }}</p>
            </div>
            <button type='button' class='btn btn-primary btn-block' v-on:click='getResult'
                    :disabled='!job_id && !ret_pdb_id'>
              Get Result
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Vue from 'vue';
import VeeValidate from 'vee-validate';
import Resource from 'vue-resource';
import BootstrapVue from 'bootstrap-vue';

Vue.use(BootstrapVue);
Vue.use(Resource);
Vue.use(VeeValidate);

let combinations = function (array) {
  let combos = [];
  for (let i = 0; i < array.length - 1; i++) {
  // This is where you'll capture that last value
    for (let j = i + 1; j < array.length; j++) {
      combos.push(array[i].name + array[j].name);
    }
  }
  return combos;
};

export default {
  name: 'Submit',
  data: () => ({
    file: '',
    pdb_id: '',
    email: '',
    file_path: 'fake_path',
    value: [],
    all_chains: [],
    selected_chains: [],
    selected_pairs: [],
    new_chain: {},
    monster_url: 'https://cors-anywhere.herokuapp.com/http://monster.northwestern.edu:8081/',
    job_id: '',
    ret_pdb_id: '',
    loading: false,
    showSuccessAlert: false,
    showFailAlert: false,
  }),
  computed: {
    all_pairs: function () {
      return combinations(this.selected_chains);
    },
  },
  watch: {
    selected_chains: function () {
      this.selected_pairs = [];
    },
  },
  methods: {
    getResult: function () {
      this.$router.push({name: 'Result', params: { job_id: this.job_id }});
    },
    handleFileUpload: function () {
      this.file = this.$refs.file.files[0];
    },
    parseText: function () {
      let formData = new FormData();
      formData.append('pdbFile', this.file);
      formData.append('pdbId', this.pdb_id);
      this.$http.post(this.$server_url + '/upload', formData).then(function (response) {
        console.log(response);
        this.all_chains = response.body.chains;
        this.file_path = response.body.file_path;
        this.selected_pairs = [];
      }, function (response) {
        alert('File Upload failed. Check your browser console for details');
        console.error(response);
      });
    },
    selectAllChains: function () {
      if (this.selected_chains === this.all_chains) {
        this.selected_chains = [];
      } else {
        this.selected_chains = this.all_chains;
      }
    },
    selectAllPairs: function () {
      if (this.selected_pairs === this.all_pairs) {
        this.selected_pairs = [];
      } else {
        this.selected_pairs = this.all_pairs;
      }
    },
    submitJob: function () {
      if (!this.email) {
        alert('Missing required fields');
        return;
      }
      this.loading = true;
      fetch(this.monster_url, {
        method: 'POST',
        body: this.makeXML(),
        headers: {
          'Content-Type': 'text/xml',
        },
      }).then(res => res.text())
        .then(() => {
          this.loading = false;
          this.showSuccessAlert = true;
        }).catch((err) => {
          this.loading = false;
          console.error(err);
          this.showFailAlert = true;
        });
    },
    getChainXML: function (id) {
      for (let chain of this.all_chains) {
        if (chain.name === id) {
          return `<Chain index='${chain.name}'><Start>${chain.start}</Start><End>${chain.end}</End><Natural>${chain.name}</Natural></Chain>`;
        }
      }
    },
    makeXML: function () {
      let index = Math.random().toString(36).slice(-10);
      let txt = `<ChainPairs index='${index}' protons='false'><File>${this.file_path}</File><Email>${this.email}</Email><IP>Unknown</IP><OS>Unknown</OS>`;
      for (let chain_pair of this.selected_pairs) {
        txt += `<ChainPair index='${chain_pair}'>${this.getChainXML(chain_pair[0])}${this.getChainXML(chain_pair[1])}</ChainPair>`;
      }
      txt += '</ChainPairs>';
      let es_txt = this.escapeXml(txt);
      let xml =
        `<?xml version='1.0'?>
        <methodCall>
          <methodName>Monster.go</methodName>
          <params>
            <param>
              <value>
                <string>
                ${es_txt}
              </string>
            </value>
          </param>
          </params>
        </methodCall>`;
      console.log(xml);
      return xml;
    },
    escapeXml: function (unsafe) {
      return unsafe.replace(/[<>&'']/g, function (c) {
        switch (c) {
          case '<': return '&lt;';
          case '>': return '&gt;';
          case '&': return '&amp;';
          case '\'': return '&apos;';
          case '"': return '&quot;';
        }
      });
    },
  },
};
</script>
