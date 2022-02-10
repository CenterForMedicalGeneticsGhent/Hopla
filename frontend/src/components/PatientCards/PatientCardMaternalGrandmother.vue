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
  import PatientCardGeneral from "./PatientCardGeneral.vue";
  import cloneDeep from 'lodash/cloneDeep';
  
  var configMaternalGrandmotherDefault = {
    sampleID: "",
    gender: "F",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
  };
  var configMaternalGrandmotherAbsentDefault = {
    sampleID: "U6",
    gender: "F",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
  };

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
        config: cloneDeep(configMaternalGrandmotherAbsentDefault),
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
        return `M. Grandmother`;
      },
      cardType: function(){
        return "maternalGrandmother";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
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