<template>
<div
id="input_maternal_grandfather_card"
>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U5'"
>
  <v-btn
  id="input_maternal_grandfather_add"
  @click="addMaternalGrandfather()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/maternalGrandfather.png"
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
  @removeCard="removeMaternalGrandfather()"
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

  // Templates
  import {templateMaternalGrandfather} from "../Templates";
  var configMaternalGrandfatherAbsentDefault = cloneDeep(templateMaternalGrandfather);
  var configMaternalGrandfatherDefault = cloneDeep(templateMaternalGrandfather);
  configMaternalGrandfatherDefault.sampleID="maternalGrandfatherID";
  

  export default Vue.extend({
    name: 'PatientCardMaternalGrandfather',
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
      config: {
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        },
      },
      title: function(){
        return `M. Grandfather`;
      },
      cardType: function(){
        return "maternalGrandfather";
      }
    },
    methods:{
      addMaternalGrandfather:function(){
        this.config=cloneDeep(configMaternalGrandfatherDefault);
      },
      removeMaternalGrandfather:function(){
        this.config=cloneDeep(configMaternalGrandfatherAbsentDefault);
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