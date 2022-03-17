<template>
<PedigreeGroup
width="550px"
imgType='grandparents1'
title="Paternal Grandparents"
imgLicense="Designed by FreePlk from Flaticon"
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
      <PatientCardPaternalGrandmother 
      v-model="config['paternalGrandmother']"
      />
    </v-col>
  </v-row>
</PedigreeGroup>
</template>

<script>
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardPaternalGrandfather from "../PatientCards/PatientCardPaternalGrandfather.vue";
  import PatientCardPaternalGrandmother from "../PatientCards/PatientCardPaternalGrandmother.vue";

  export default Vue.extend({
    name: 'PedigreeGroupGrandparentsPaternal',
    components:{
      PedigreeGroup,
      PatientCardPaternalGrandfather,
      PatientCardPaternalGrandmother,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
      }
    },
    computed:{
      config: {
        get:function(){
          return this.value;
        },
        set:function(d){
          this.$emit('input',d);
        },
      }
    },
    methods:{
      //CODE
    },
    mounted: function(){
      //CODE
    }  
    })
</script>