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
  import PatientCardGeneral from "./PatientCardGeneral.vue";
  import cloneDeep from 'lodash/cloneDeep';
  
  var configPaternalGrandmotherDefault = {
    sampleID: "",
    gender: "F",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
  };
  var configPaternalGrandmotherAbsentDefault = {
    sampleID: "U4",
    gender: "F",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
  };

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
        config: cloneDeep(configPaternalGrandmotherAbsentDefault),
      };
    },
    computed: {
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
      },
      title: function(){
        return `P. Grandmother`;
      },
      cardType: function(){
        return "paternalGrandmother";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
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
      configWatcher:{
        handler: function(newVal,oldVal){
          if (oldVal != newVal){
            this.handleInput();
          }
        },
        deep:false,
        immediate:true,
      },
    },
    })
</script>