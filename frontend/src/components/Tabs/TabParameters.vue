<template>
<v-container>
  <InputFileVCF v-model="fileVCF" />
  <InputFileCytoband v-model="fileCytoband" />
  <InputRegions v-model="regions" />
  <InputDisease v-model="disease" />
  <InputInheritance v-model="inheritance" />
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputFileVCF from "../Inputs/InputFileVCF.vue";
  import InputFileCytoband from "../Inputs/InputFileCytoband.vue";
  import InputRegions from "../Inputs/InputRegions.vue";
  import InputDisease from "../Inputs/InputDisease.vue";
  import InputInheritance from "../Inputs/InputInheritance.vue";


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputFileVCF,
      InputFileCytoband,
      InputRegions,
      InputDisease,
      InputInheritance,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        fileVCF: this.value.fileVCF,
        fileCytoband: this.value.fileCytoband,
        regions:this.value.regions,
        disease: this.value.disease,
        inheritance: this.value.inheritance,
      }
    },
    computed:{
      config: function(){
        return {
          fileVCF: this.fileVCF,
          fileCytoband: this.fileCytoband,
          regions: this.regions,
          disease: this.disease,
          inheritance: this.inheritance,
        };
      },
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
      },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      }
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