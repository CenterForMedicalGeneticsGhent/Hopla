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
        src="../../assets/father.png"
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
  import Vue from 'vue'
  import PatientCardGeneral from "./PatientCardGeneral.vue";
  import cloneDeep from 'lodash/cloneDeep';
  
  var configFatherDefault = {
    sampleID: "fatherID",
    gender: "M",
    keepInformativeIDs: true,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
  };
  var configFatherAbsentDefault = {
    sampleID: "U1",
    gender: "M",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: "hide",
    keepLimitIDHardAF: "hide",
    keepLimitIDSoftDP: "hide",
  };

  export default Vue.extend({
    name: 'PatientCardFather',
    components: {
      PatientCardGeneral,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: cloneDeep(configFatherAbsentDefault),
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
        return `Father`;
      },
      cardType: function(){
        return "father";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
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