<template>
<PatientCardGeneral
v-model="config"
:title="title"
:cardType="cardType"
@removeCard="removeCard()"
:genderLocked="true"
/>
</template>

<script>
  // Imports
  import Vue from 'vue'
  import PatientCardGeneral from "./PatientCardGeneral.vue";
  import cloneDeep from 'lodash/cloneDeep';
  
  var configFatherDefault = {
    sampleID: "",
    gender: "M",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
  };
  var configFatherAbsentDefault = {
    sampleID: "U1",
    gender: "M",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
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
      removeCard:function(){
        this.$emit('removeCard');
      }
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