<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U3'"
>
  <v-btn
  @click="addPaternalGrandfather()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/paternalGrandfather.png"
      />
    </v-avatar>
  </v-btn>
</v-col>
<v-col 
class="d-flex justify-center align-center"
v-else
>
  <PatientCardGeneral
  v-model="config"
  :title="title"
  :cardType="cardType"
  @removeCard="removePaternalGrandfather()"
  :genderLocked="true"
  />
</v-col>
</div>
</template>

<script>
  // Imports
  import cloneDeep from 'lodash/cloneDeep';

  // Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  //Templates
  import {templatePaternalGrandfather} from "../Templates";
  var configPaternalGrandfatherAbsentDefault = cloneDeep(templatePaternalGrandfather);
  var configPaternalGrandfatherDefault = cloneDeep(configPaternalGrandfatherAbsentDefault);
  configPaternalGrandfatherDefault.sampleID= "paternalGrandfatherID";


  export default {
    name: 'PatientCardPaternalGrandfather',
    emits: ['update:modelValue'],
    components: {
      PatientCardGeneral,
    },
    props:{
      modelValue: Object,  
    },
    data: function() {
      return {
      };
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
      title: function(){
        return `P. Grandfather`;
      },
      cardType: function(){
        return "paternalGrandfather";
      }
    },
    methods:{
      addPaternalGrandfather:function(){
        this.config=cloneDeep(configPaternalGrandfatherDefault);
      },
      removePaternalGrandfather:function(){
        this.config=cloneDeep(configPaternalGrandfatherAbsentDefault);
      },
    },
    mounted: function(){
      //CODE
    },
    watch:{
      //CODE
    },
    }
</script>