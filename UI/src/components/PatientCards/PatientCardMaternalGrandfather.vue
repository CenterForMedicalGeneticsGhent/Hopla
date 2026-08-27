<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U5'"
>
  <v-btn
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
  import cloneDeep from 'lodash/cloneDeep';

  // Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  // Templates
  import {templateMaternalGrandfather} from "../Templates";
  var configMaternalGrandfatherAbsentDefault = cloneDeep(templateMaternalGrandfather);
  var configMaternalGrandfatherDefault = cloneDeep(templateMaternalGrandfather);
  configMaternalGrandfatherDefault.sampleID="maternalGrandfatherID";
  

  export default {
    name: 'PatientCardMaternalGrandfather',
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
      config: {
        get: function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
    }
</script>