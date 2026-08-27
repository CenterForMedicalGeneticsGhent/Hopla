<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U1'"
>
  <v-btn
  @click="addFather()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        :src="fatherImg"
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
  import cloneDeep from 'lodash/cloneDeep';
  import fatherImg from '../../assets/father.png';

  //Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  //Templates 
  import {templateFather} from "../Templates";
  var configFatherAbsentDefault = cloneDeep(templateFather);
  var configFatherDefault = cloneDeep(configFatherAbsentDefault);
  configFatherDefault.sampleID="fatherID";
  

  export default {
    name: 'PatientCardFather',
    emits: ['update:modelValue'],
    components: {
      PatientCardGeneral,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
        fatherImg,
      };
    },
    computed: {
      config: {
        get: function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
    }
</script>