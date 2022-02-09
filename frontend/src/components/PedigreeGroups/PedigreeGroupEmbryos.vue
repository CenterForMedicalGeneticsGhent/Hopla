<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
v-model="config"
>
  <v-row
  v-for="row in countRows()"
  :key="row"
  >
    <v-col
    v-for="col in colsMax"
    :key="col"
    >
      <PatientCardEmbryo
      v-if="((row-1)*colsMax + col)<=countEmbryos()" 
      v-model="config[(row-1)*colsMax + col-1]"
      :i="(row-1)*colsMax + col-1"
      />
    </v-col>
  </v-row>
  <v-row> <v-col class="d-flex justify-center align-center"> 
    <v-btn>
      <v-icon>
        mdi-plus
      </v-icon>
      <v-avatar 
      size="32"
      tile
      >
        <v-img
          src="../../assets/embryos.png"
        />
      </v-avatar>
    </v-btn>
  </v-col></v-row>
</PedigreeGroup>
</template>

<script>
  import Vue from 'vue';
  import cloneDeep from 'lodash/cloneDeep';
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardEmbryo from "../PatientCards/PatientCardEmbryo.vue";

  // configEmbryoDefault
  var configEmbryosDefault = {
    sampleID: "",
    gender: "NA",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
  };

  export default Vue.extend({
    name: 'PedigreeGroupEmbryos',
    components:{
      PedigreeGroup,
      PatientCardEmbryo,
    },
    props:{
      value: Array,
    },
    data: function() {
      return {
        config: [
          cloneDeep(configEmbryosDefault),
          cloneDeep(configEmbryosDefault),
          cloneDeep(configEmbryosDefault),
          cloneDeep(configEmbryosDefault),
          cloneDeep(configEmbryosDefault),
          cloneDeep(configEmbryosDefault),
        ],
        colsMax: 4,
      }
    },
    computed:{
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
      },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
      countEmbryos: function(){
        return this.config.length;
      },
      countRows: function(){
        return Math.ceil(this.countEmbryos()/this.colsMax);
      },
    },
    mounted: function(){
      //code
    },
    watch:{
      configWatcher:{
        handler: function(newVal,oldVal){
          if (oldVal != newVal){
            this.handleInput();
          }
        },
        deep:false,
        immediate:true,
      },
    },  
    })
</script>