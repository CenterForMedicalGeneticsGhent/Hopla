<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
v-model="config"
>
  <PatientCardGeneral v-model="patientInfo"/>
</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  export default Vue.extend({
    name: 'PedigreeGroupEmbryos',
    components:{
      PedigreeGroup,
      PatientCardGeneral,
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