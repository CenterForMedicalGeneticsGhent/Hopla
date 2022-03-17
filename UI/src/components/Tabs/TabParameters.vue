<template>
<v-container>
  <v-row
  align="center"
  justify="center"  
  >
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsMandatory v-model="config.fileVCF" />
    </v-col>
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsOptional v-model="config.fileCytoband" />
    </v-col>
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsVariantInclusion v-model="config.afHardLimit" />
    </v-col>
  </v-row>

  <v-row
  align="center"
  justify="center"
  >
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsSampleDisease v-model="config.sampleDisease" />
    </v-col>
  </v-row>

  <v-row
  align="center"
  justify="center"
  >
    <v-col class="d-flex justify-center align-center" :cols="4">
      <InputArgumentsMerlinProfiles v-model="config.merlinProfiles" />
    </v-col>
    <v-col class="d-flex justify-center align-center" :cols="8" >
    </v-col>
  
  </v-row>
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
      };
    },
    computed:{
      config:{
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        }
      },
    },
    methods:{
      //CODE
    },
    watch:{
      //CODE
    },  
    })
</script>