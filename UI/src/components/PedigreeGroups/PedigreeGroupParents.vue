<template>
<PedigreeGroup
width="550px"
imgType='parents'
title="Parents"
imgLicense="Designed by FreePlk from Flaticon"
v-model="config"
>
  <v-row
  align="center"
  justify="center"
  >
    <v-col>
      <PatientCardFather 
      v-model="config['father']"
      />
    </v-col>
    <v-col>
      <PatientCardMother 
      v-model="config['mother']"
      />
    </v-col>
  </v-row>
</PedigreeGroup>
</template>

<script>
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardFather from "../PatientCards/PatientCardFather.vue";
  import PatientCardMother from "../PatientCards/PatientCardMother.vue";

  export default Vue.extend({
    name: 'PedigreeGroupParents',
    components:{
      PedigreeGroup,
      PatientCardFather,
      PatientCardMother,
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
        set: function(d){
          this.$emit('input',d);
        },
      },
    },
    methods:{
    },
    mounted: function(){
      //CODE
    }  
    })
</script>