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
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardPaternalGrandfather from "../PatientCards/PatientCardPaternalGrandfather.vue";
  import PatientCardPaternalGrandmother from "../PatientCards/PatientCardPaternalGrandmother.vue";

  export default {
    name: 'PedigreeGroupGrandparentsPaternal',
    emits: ['update:modelValue'],
    components:{
      PedigreeGroup,
      PatientCardPaternalGrandfather,
      PatientCardPaternalGrandmother,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
      }
    },
    computed:{
      config: {
        get:function(){
          return this.modelValue;
        },
        set:function(d){
          this.$emit('update:modelValue',d);
        },
      }
    },
    methods:{
      //CODE
    },
    mounted: function(){
      //CODE
    }  
    }
</script>