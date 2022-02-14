<template>
<v-container>
  <InputArgumentsMandatory v-model="fileVCF" />
  <InputFileCytoband v-model="fileCytoband" />
  <InputRegions v-model="regions" />
  <InputDisease v-model="disease" />
  <InputInheritance v-model="inheritance" />
  <InputSequencingNote v-model="sequencingNote" />
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputArgumentsMandatory from "../Inputs/InputArgumentsMandatory.vue";
  import InputFileCytoband from "../Inputs/InputFileCytoband.vue";
  import InputRegions from "../Inputs/InputRegions.vue";
  import InputDisease from "../Inputs/InputDisease.vue";
  import InputInheritance from "../Inputs/InputInheritance.vue";
  import InputSequencingNote from "../Inputs/InputSequencingNote.vue";


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputArgumentsMandatory,
      InputFileCytoband,
      InputRegions,
      InputDisease,
      InputInheritance,
      InputSequencingNote,
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
        sequencingNote: this.value.sequencingNote,
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
          sequencingNote: this.sequencingNote,
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