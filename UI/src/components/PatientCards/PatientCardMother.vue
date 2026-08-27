<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U2'"
>
  <v-btn
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
        :src="motherImg"
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
  import cloneDeep from 'lodash/cloneDeep';
  import motherImg from '../../assets/mother.png';
  
   //Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  //Templates 
  import {templateMother} from "../Templates";
  var configMotherAbsentDefault = cloneDeep(templateMother);
  var configMotherDefault = cloneDeep(configMotherAbsentDefault);
  configMotherDefault.sampleID="motherID";

  export default {
    name: 'PatientCardMother',
    emits: ['update:modelValue'],
    components: {
      PatientCardGeneral,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
      
        motherImg,
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
  }
</script>