<template>
<v-container>
  <InputFileVCF v-model="fileVCF" />
  <InputFileCytoband v-model="fileCytoband" />
  <InputChr v-model="chr" />
  <InputChrStart v-model="chrStart" />
  <InputChrEnd v-model="chrEnd" />
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputFileVCF from "../Inputs/InputFileVCF.vue";
  import InputFileCytoband from "../Inputs/InputFileCytoband.vue";
  import InputChr from "../Inputs/InputChr.vue";
  import InputChrStart from "../Inputs/InputChrStart.vue";
  import InputChrEnd from "../Inputs/InputChrEnd.vue";


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputFileVCF,
      InputFileCytoband,
      InputChr,
      InputChrStart,
      InputChrEnd,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        fileVCF: this.value.fileVCF,
        fileCytoband: this.value.fileCytoband,
        chr: "chr1",
        chrStart: 1,
        chrEnd: 99999999999,
      }
    },
    computed:{
      config: function(){
        return {
          fileVCF: this.fileVCF,
          fileCytoband: this.fileCytoband,
          chr: this.chr,
          chrStart: this.chrStart,
          chrEnd: this.chrEnd,
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