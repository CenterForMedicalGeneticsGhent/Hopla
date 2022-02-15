<template>
<v-container>
  <v-row
  align="center"
  justify="center"  
  >
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

  <v-row
  align="center"
  justify="center"
  >
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsSampleDisease v-model="sampleDisease" />
    </v-col>
  </v-row>

  <v-row
  align="center"
  justify="center"
  >
    <v-col class="d-flex justify-center align-center" :cols="4">
      <InputArgumentsMerlinProfiles v-model="merlinProfiles" />
    </v-col>
    <v-col class="d-flex justify-center align-center" :cols="8" >
    </v-col>
  
  </v-row>
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputArgumentsMandatory from "../Inputs/InputArgumentsMandatory.vue";
  import InputArgumentsOptional from "../Inputs/InputArgumentsOptional.vue";
  import InputArgumentsVariantInclusion from "../Inputs/InputArgumentsVariantInclusion.vue";
  import InputArgumentsSampleDisease from "../Inputs/InputArgumentsSampleDisease.vue";
  import InputArgumentsMerlinProfiles from "../Inputs/InputArgumentsMerlinProfiles.vue";


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputArgumentsMandatory,
      InputArgumentsOptional,
      InputArgumentsVariantInclusion,
      InputArgumentsSampleDisease,
      InputArgumentsMerlinProfiles,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        fileVCF: this.value.fileVCF,
        fileCytoband: this.value.fileCytoband,
        afHardLimit: this.value.afHardLimit,
        sampleDisease: this.value.sampleDisease,
        merlinProfiles: this.value.merlinProfiles,
      }
    },
    computed:{
      config: function(){
        return {
          fileVCF: this.fileVCF,
          fileCytoband: this.fileCytoband,
          afHardLimit: this.afHardLimit,
          sampleDisease: this.sampleDisease,
          merlinProfiles: this.merlinProfiles,
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