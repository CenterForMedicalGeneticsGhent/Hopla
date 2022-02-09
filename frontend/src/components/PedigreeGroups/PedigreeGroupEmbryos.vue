<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
:addBtn="true"
v-model="config"
>
  <PatientCardEmbryo 
  v-for="(item,index) in config"
  :key="index"
  v-model="config[index]"
  />
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
        config: [cloneDeep(configEmbryosDefault),cloneDeep(configEmbryosDefault)],
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
    },
    mounted: function(){
      //CODE
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