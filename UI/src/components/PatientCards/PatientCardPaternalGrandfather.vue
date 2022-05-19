<template>
<div
id="input_paternal_grandfather_card"
>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U3'"
>
  <v-btn
  id="input_paternal_grandfather_add"
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
  import Vue from 'vue'
  import cloneDeep from 'lodash/cloneDeep';

  // Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  //Templates
  import {templatePaternalGrandfather} from "../Templates";
  var configPaternalGrandfatherAbsentDefault = cloneDeep(templatePaternalGrandfather);
  var configPaternalGrandfatherDefault = cloneDeep(configPaternalGrandfatherAbsentDefault);
  configPaternalGrandfatherDefault.sampleID= "paternalGrandfatherID";


  export default Vue.extend({
    name: 'PatientCardPaternalGrandfather',
    components: {
      PatientCardGeneral,
    },
    props:{
      value: Object,  
    },
    data: function() {
      return {
      };
    },
    computed: {
      config:{
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
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
    })
</script>