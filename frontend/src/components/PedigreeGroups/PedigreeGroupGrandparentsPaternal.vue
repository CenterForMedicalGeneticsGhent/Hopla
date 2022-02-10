<template>
<PedigreeGroup
width="550px"
imgType='grandparents1'
title="Paternal Grandparents"
v-model="config"
>
  <v-row
  align="center"
  justify="center"
  >
    <v-col>
      <PatientCardPaternalGrandfather 
      v-model="config['paternalGrandfather']"
      />
    </v-col>
    <v-col>
      <PatientCardPaternalGrandfather 
      v-model="config['paternalGrandfather']"
      />
    </v-col>
  </v-row>

  {{ config }}

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardPaternalGrandfather from "../PatientCards/PatientCardPaternalGrandfather.vue";

  export default Vue.extend({
    name: 'PedigreeGroupGrandparentsPaternal',
    components:{
      PedigreeGroup,
      PatientCardPaternalGrandfather,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: this.value,
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