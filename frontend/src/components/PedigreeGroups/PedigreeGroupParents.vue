<template>
<PedigreeGroup
width="600px"
imgType='parents'
title="Parents"
v-model="config"
>
  <v-row>
    <v-col class="d-flex justify-center align-center">
      <PatientCardFather 
      v-model="config['Father']"
      />
    </v-col>
    <v-col class="d-flex justify-center align-center">
    </v-col>
  </v-row>

  {{ config }}

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardFather from "../PatientCards/PatientCardFather.vue";

  export default Vue.extend({
    name: 'PedigreeGroupParents',
    components:{
      PedigreeGroup,
      PatientCardFather,
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