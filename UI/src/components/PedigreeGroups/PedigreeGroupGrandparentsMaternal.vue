<template>
<PedigreeGroup
width="550px"
imgType='grandparents2'
title="Maternal Grandparents"
v-model="config"
>
  <v-row
  align="center"
  justify="center"
  >
    <v-col>
      <PatientCardMaternalGrandfather 
      v-model="config['maternalGrandfather']"
      />
    </v-col>
    <v-col>
      <PatientCardMaternalGrandmother 
      v-model="config['maternalGrandmother']"
      />
    </v-col>
  </v-row>
</PedigreeGroup>
</template>

<script>
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardMaternalGrandfather from "../PatientCards/PatientCardMaternalGrandfather.vue";
  import PatientCardMaternalGrandmother from "../PatientCards/PatientCardMaternalGrandmother.vue";

  export default Vue.extend({
    name: 'PedigreeGroupGrandparentsPaternal',
    components:{
      PedigreeGroup,
      PatientCardMaternalGrandfather,
      PatientCardMaternalGrandmother,
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