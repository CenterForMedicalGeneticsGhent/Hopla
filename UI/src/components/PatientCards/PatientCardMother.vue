<template>
<div
id="input_mother_card"
>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U2'"
>
  <v-btn
  id="input_mother_add"
  @click="addMother()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/mother.png"
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
  @removeCard="removeMother()"
  :genderLocked="true"
  />
</v-col>
</div>
</template>

<script>
  // Imports
  import Vue from 'vue'
  import cloneDeep from 'lodash/cloneDeep';
  
   //Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  //Templates 
  import {templateMother} from "../Templates";
  var configMotherAbsentDefault = cloneDeep(templateMother);
  var configMotherDefault = cloneDeep(configMotherAbsentDefault);
  configMotherDefault.sampleID="motherID";

  export default Vue.extend({
    name: 'PatientCardMother',
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
        return `Mother`;
      },
      cardType: function(){
        return "mother";
      }
    },
    methods:{
      addMother:function(){
        this.config=cloneDeep(configMotherDefault);
      },
      removeMother:function(){
        this.config=cloneDeep(configMotherAbsentDefault);
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