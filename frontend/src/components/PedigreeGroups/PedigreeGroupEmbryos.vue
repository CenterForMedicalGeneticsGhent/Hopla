<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
v-model="config"
>
  <PatientCardEmbryo v-model="patientInfo"/>
</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardEmbryo from "../PatientCards/PatientCardEmbryo.vue";

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
        patientInfo: null,
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