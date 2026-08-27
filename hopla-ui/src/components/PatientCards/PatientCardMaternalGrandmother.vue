<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U6'"
>
  <v-btn
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
        :src="maternalGrandmotherImg"
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
  import cloneDeep from 'lodash/cloneDeep';
  import maternalGrandmotherImg from '../../assets/maternalGrandmother.png';

  // Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  // Templates
  import {templateMaternalGrandmother} from "../Templates";
  var configMaternalGrandmotherAbsentDefault = cloneDeep(templateMaternalGrandmother);
  var configMaternalGrandmotherDefault = cloneDeep(templateMaternalGrandmother);
  configMaternalGrandmotherDefault.sampleID="maternalGrandmotherID";

  export default {
    name: 'PatientCardMaternalGrandmother',
    emits: ['update:modelValue'],
    components: {
      PatientCardGeneral,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
        maternalGrandmotherImg,
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
    }
</script>