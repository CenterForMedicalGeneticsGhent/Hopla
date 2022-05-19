<template>
<div
id="input_paternal_grandmother_card"
>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U4'"
>
  <v-btn
  id="input_paternal_grandmother_add"
  @click="addPaternalGrandmother()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/paternalGrandmother.png"
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
  @removeCard="removePaternalGrandmother()"
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
  import {templatePaternalGrandmother} from "../Templates";
  var configPaternalGrandmotherAbsentDefault = cloneDeep(templatePaternalGrandmother);
  var configPaternalGrandmotherDefault = cloneDeep(configPaternalGrandmotherAbsentDefault);
  configPaternalGrandmotherDefault.sampleID="paternalGrandmotherID";

  

  export default Vue.extend({
    name: 'PatientCardPaternalGrandmother',
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
        return `P. Grandmother`;
      },
      cardType: function(){
        return "paternalGrandmother";
      }
    },
    methods:{
      addPaternalGrandmother:function(){
        this.config=cloneDeep(configPaternalGrandmotherDefault);
      },
      removePaternalGrandmother:function(){
        this.config=cloneDeep(configPaternalGrandmotherAbsentDefault);
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