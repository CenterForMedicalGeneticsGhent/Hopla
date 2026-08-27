<template>
<PedigreeGroup
width="550px"
imgType='grandparents2'
title="Maternal Grandparents"
imgLicense="Designed by FreePlk from Flaticon"
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
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardMaternalGrandfather from "../PatientCards/PatientCardMaternalGrandfather.vue";
  import PatientCardMaternalGrandmother from "../PatientCards/PatientCardMaternalGrandmother.vue";

  export default {
    name: 'PedigreeGroupGrandparentsPaternal',
    emits: ['update:modelValue'],
    components:{
      PedigreeGroup,
      PatientCardMaternalGrandfather,
      PatientCardMaternalGrandmother,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
      }
    },
    computed: {
      config:{
        get: function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
        },
      },
    },
    methods:{
      //CODE 
    },
    mounted: function(){
      //CODE
    }  
    }
</script>