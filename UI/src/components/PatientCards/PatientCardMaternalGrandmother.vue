<template>
<div
id="input_maternal_grandmother_card"
>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U6'"
>
  <v-btn
  id="input_maternal_grandmother_add"
  @click="addMaternalGrandmother()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/maternalGrandmother.png"
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
  @removeCard="removeMaternalGrandmother()"
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
  import {templateMaternalGrandmother} from "../Templates";
  var configMaternalGrandmotherAbsentDefault = cloneDeep(templateMaternalGrandmother);
  var configMaternalGrandmotherDefault = cloneDeep(templateMaternalGrandmother);
  configMaternalGrandmotherDefault.sampleID="maternalGrandmotherID";

  export default Vue.extend({
    name: 'PatientCardMaternalGrandmother',
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
        return `M. Grandmother`;
      },
      cardType: function(){
        return "maternalGrandmother";
      }
    },
    methods:{
      addMaternalGrandmother:function(){
        this.config=cloneDeep(configMaternalGrandmotherDefault);
      },
      removeMaternalGrandmother:function(){
        this.config=cloneDeep(configMaternalGrandmotherAbsentDefault);
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