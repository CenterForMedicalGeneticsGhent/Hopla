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
        src="../../assets/mother.png"
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
  import Vue from 'vue'
  import PatientCardGeneral from "./PatientCardGeneral.vue";
  import cloneDeep from 'lodash/cloneDeep';
  
  var configMotherDefault = {
    sampleID: "",
    gender: "F",
    keepInformativeIDs: true,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
  };
  var configMotherAbsentDefault = {
    sampleID: "U2",
    gender: "F",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: "hide",
    keepLimitIDHardAF: "hide",
    keepLimitIDSoftDP: "hide",
  };

  export default Vue.extend({
    name: 'PatientCardMother',
    components: {
      PatientCardGeneral,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: cloneDeep(configMotherAbsentDefault),
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
        return `Mother`;
      },
      cardType: function(){
        return "mother";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
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