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
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardFather from "../PatientCards/PatientCardFather.vue";
  import PatientCardMother from "../PatientCards/PatientCardMother.vue";

  export default {
    name: 'PedigreeGroupParents',
    emits: ['update:modelValue'],
    components:{
      PedigreeGroup,
      PatientCardFather,
      PatientCardMother,
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
        set: function(d){
          this.$emit('update:modelValue',d);
        },
      },
    },
    methods:{
    },
    mounted: function(){
      //CODE
    }  
    }
</script>