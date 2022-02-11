<template>
<v-container>
  <InputFileVCF v-model="fileVCF" />
  <InputFileCytoband v-model="fileCytoband" />
  <InputRegion v-model="region" />
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputFileVCF from "../Inputs/InputFileVCF.vue";
  import InputFileCytoband from "../Inputs/InputFileCytoband.vue";
  import InputRegion from "../Inputs/InputRegion.vue"


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputFileVCF,
      InputFileCytoband,
      InputRegion,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        fileVCF: this.value.fileVCF,
        fileCytoband: this.value.fileCytoband,
        region:{
          chr: "chr1",
          chrStart: 1,
          chrEnd: 99999999999,
        },
      }
    },
    computed:{
      config: function(){
        return {
          fileVCF: this.fileVCF,
          fileCytoband: this.fileCytoband,
          region: this.region,
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