<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U4'"
>
  <v-btn
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
        :src="paternalGrandmotherImg"
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
  import cloneDeep from 'lodash/cloneDeep';
  import paternalGrandmotherImg from '../../assets/paternalGrandmother.png';

  // Components
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  // Templates
  import {templatePaternalGrandmother} from "../Templates";
  var configPaternalGrandmotherAbsentDefault = cloneDeep(templatePaternalGrandmother);
  var configPaternalGrandmotherDefault = cloneDeep(configPaternalGrandmotherAbsentDefault);
  configPaternalGrandmotherDefault.sampleID="paternalGrandmotherID";

  

  export default {
    name: 'PatientCardPaternalGrandmother',
    emits: ['update:modelValue'],
    components: {
      PatientCardGeneral,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
        paternalGrandmotherImg,
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
    }
</script>