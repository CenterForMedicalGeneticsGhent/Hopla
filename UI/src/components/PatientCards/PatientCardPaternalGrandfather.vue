<template>
<div>
<v-col 
class="d-flex justify-center align-center"
v-if="config['sampleID']=='U3'"
>
  <v-btn
  @click="addPaternalGrandfather()"
  >
    <v-icon>
      mdi-plus
    </v-icon>
    <v-avatar 
    size="32"
    tile
    >
      <v-img
        src="../../assets/paternalGrandfather.png"
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
  @removeCard="removePaternalGrandfather()"
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
  
  var configPaternalGrandfatherDefault = {
    sampleID: "paternalGrandfatherID",
    gender: "M",
    keepInformativeIDs: true,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
  };
  var configPaternalGrandfatherAbsentDefault = {
    sampleID: "U3",
    gender: "M",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: "hide",
    keepLimitIDHardAF: "hide",
    keepLimitIDSoftDP: "hide",
  };

  export default Vue.extend({
    name: 'PatientCardPaternalGrandfather',
    components: {
      PatientCardGeneral,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: cloneDeep(configPaternalGrandfatherAbsentDefault),
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
        return `P. Grandfather`;
      },
      cardType: function(){
        return "paternalGrandfather";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
      addPaternalGrandfather:function(){
        this.config=cloneDeep(configPaternalGrandfatherDefault);
      },
      removePaternalGrandfather:function(){
        this.config=cloneDeep(configPaternalGrandfatherAbsentDefault);
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