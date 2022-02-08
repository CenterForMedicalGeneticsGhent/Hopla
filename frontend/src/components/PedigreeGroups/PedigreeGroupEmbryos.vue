<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
v-model="config"
>
  <PatientCardEmbryo v-model="patientInfo"/>
  {{patientInfo}}
</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardEmbryo from "../PatientCards/PatientCardEmbryo.vue";

  // configEmbryoDefault
  var configEmbryoDefault = {
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
      value: Object,
    },
    data: function() {
      return {
        config: this.value,
        patientInfo: configEmbryoDefault,
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
    },
    mounted: function(){
      //CODE
    }  
    })
</script>