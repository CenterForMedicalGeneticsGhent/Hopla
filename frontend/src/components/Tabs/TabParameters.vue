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

  <v-row>
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsSampleDisease v-model="sampleDisease" />
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


  export default Vue.extend({
    name: 'TabParameters',
    components:{
      InputArgumentsMandatory,
      InputArgumentsOptional,
      InputArgumentsVariantInclusion,
      InputArgumentsSampleDisease,
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
      }
    },
    computed:{
      config: function(){
        return {
          fileVCF: this.fileVCF,
          fileCytoband: this.fileCytoband,
          afHardLimit: this.afHardLimit,
          sampleDisease: this.sampleDisease,
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