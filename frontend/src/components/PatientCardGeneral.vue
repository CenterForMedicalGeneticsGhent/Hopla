<template>
<v-card
width="250px"
>
  <v-card-title> 
  <v-avatar 
  size="48"
  tile
  >
    <v-img
      src="../assets/embryos.png"
    />
  </v-avatar>
  <v-spacer />
  Embryo 1
  <v-spacer />
   <InputGender v-model="gender" />
  </v-card-title>
  <v-card-text
  class=""
  >
    <InputSampleID v-model="sampleID" />
    <InputInformativeIDs v-model="keepInformativeIDs" />
    <InputHeteroIDs v-model="keepHeteroIDs" />
    <InputAffected v-model="diseaseStatus" />
    {{ config }}
  </v-card-text>
</v-card>
</template>

<script lang="ts">
  // Imports
  import Vue from 'vue'
  import InputSampleID from "./InputSampleID.vue";
  import InputGender from "./InputGender.vue";
  import InputInformativeIDs from "./InputInformativeIDs.vue";
  import InputHeteroIDs from "./InputHeteroIDs.vue";
  import InputAffected from "./InputAffected.vue";

  //interfaces
  interface dataLayout {
    sampleID: string;
    gender: string;
    keepInformativeIDs: boolean;
    keepHeteroIDs: boolean;
    diseaseStatus: string;
  }
  interface configLayout {
    sampleID: string;
    gender: string;
    keepInformativeIDs: boolean;
    keepHeteroIDs: boolean;
    diseaseStatus: string;
  }

  export default Vue.extend({
    name: 'PedigreeGroup',
    components: {
      InputSampleID,
      InputGender,
      InputInformativeIDs,
      InputHeteroIDs,
      InputAffected,
    },
    props:{
      value: Object,
    },
    data: function() {
      var d: dataLayout = {
        sampleID: "",
        gender: "NA",
        keepInformativeIDs: false,
        keepHeteroIDs: false,
        diseaseStatus: "NA",
      }
      return d;
    },
    computed:{
      config: function(){
        var c: configLayout = {
          sampleID: this.sampleID,
          gender: this.gender,
          keepInformativeIDs: this.keepInformativeIDs,
          keepHeteroIDs: this.keepHeteroIDs,
          diseaseStatus: this.diseaseStatus,
        }
        return c;
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
    },
    mounted: function(){
      //CODE
    }  
    })
</script>