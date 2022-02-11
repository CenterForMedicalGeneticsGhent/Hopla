<template>
<v-container>
  <InputFileVCF v-model="fileVCF" />
  <InputFileCytoband v-model="fileCytoband" />
  <InputChr v-model="chr" />
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputFileVCF from "../Inputs/InputFileVCF.vue";
  import InputFileCytoband from "../Inputs/InputFileCytoband.vue";
  import InputChr from "../Inputs/InputChr.vue";


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputFileVCF,
      InputFileCytoband,
      InputChr,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        fileVCF: this.value.fileVCF,
        fileCytoband: this.value.fileCytoband,
        chr: "chr1",
      }
    },
    computed:{
      config: function(){
        return {
          fileVCF: this.fileVCF,
          fileCytoband: this.fileCytoband,
          chr: this.chr,
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
        immediate:false,
      },
    },  
    })
</script>