<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
v-model="config"
>
  <v-row>
    <v-col
    v-for="col in countEmbryos()"
    :key="col"
    >
      <PatientCardEmbryo
      :key="children_reload"
      v-if="col<=countEmbryos()" 
      v-model="config[col-1]"
      :i="col-1"
      @removeCard="removeEmbryo(col-1)"
      />
    </v-col>
  </v-row>
  <v-row> <v-col class="d-flex justify-center align-center"> 
    <v-btn
    @click="addEmbryo()"
    >
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
        config: [],
        colsMax: 4,
        children_reload: 0, // https://dev.to/grahammorby/rerender-a-child-component-in-vue-1462
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
      addEmbryo: function(){
        this.config.push(cloneDeep(configEmbryosDefault));
      },
      removeEmbryo: function(j){
        this.config = this.config.filter((_, index) => index != j);
        this.children_reload++;
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