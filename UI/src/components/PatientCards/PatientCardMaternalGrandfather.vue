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
  import Vue from 'vue'
  import PatientCardGeneral from "./PatientCardGeneral.vue";
  import cloneDeep from 'lodash/cloneDeep';
  
  var configMaternalGrandfatherDefault = {
    sampleID: "maternalGrandfatherID",
    gender: "M",
    keepInformativeIDs: true,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
  };
  var configMaternalGrandfatherAbsentDefault = {
    sampleID: "U5",
    gender: "M",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: "hide",
    keepLimitIDHardAF: "hide",
    keepLimitIDSoftDP: "hide",
  };

  export default Vue.extend({
    name: 'PatientCardMaternalGrandfather',
    components: {
      PatientCardGeneral,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: cloneDeep(configMaternalGrandfatherAbsentDefault),
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
        return `M. Grandfather`;
      },
      cardType: function(){
        return "maternalGrandfather";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
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