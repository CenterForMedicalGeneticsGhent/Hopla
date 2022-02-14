<template>
<v-container>
  <v-row>
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsMandatory v-model="fileVCF" />
    </v-col>
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsOptional v-model="fileCytoband" />
    </v-col>
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsVariantInclusion v-model="afHardLimit" />
    </v-col>
  </v-row>
  
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
  import InputArgumentsOptional from "../Inputs/InputArgumentsOptional.vue";
  import InputArgumentsVariantInclusion from "../Inputs/InputArgumentsVariantInclusion.vue";
  import InputRegions from "../Inputs/InputRegions.vue";
  import InputDisease from "../Inputs/InputDisease.vue";
  import InputInheritance from "../Inputs/InputInheritance.vue";
  import InputSequencingNote from "../Inputs/InputSequencingNote.vue";


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputArgumentsMandatory,
      InputArgumentsOptional,
      InputArgumentsVariantInclusion,
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
        afHardLimit: this.value.afHardLimit,
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
          afHardLimit: this.afHardLimit,
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