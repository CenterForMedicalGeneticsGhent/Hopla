<template>
<div
id="input_father_card"
>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U1'"
>
  <v-btn
  @click="addFather()"
  id="input_father_add"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/father.png"
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
  @removeCard="removeFather()"
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
  import {templateFather} from "../Templates";
  var configFatherAbsentDefault = cloneDeep(templateFather);
  var configFatherDefault = cloneDeep(configFatherAbsentDefault);
  configFatherDefault.sampleID="fatherID";
  

  export default Vue.extend({
    name: 'PatientCardFather',
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
        }
      },
      title: function(){
        return `Father`;
      },
      cardType: function(){
        return "father";
      }
    },
    methods:{
      addFather:function(){
        this.config=cloneDeep(configFatherDefault);
      },
      removeFather:function(){
        this.config=cloneDeep(configFatherAbsentDefault);
      },
    },
    mounted: function(){
      //CODE
    },
    watch:{
      //CODE
    }
    })
</script>