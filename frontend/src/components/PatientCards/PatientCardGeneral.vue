<template>
<v-card
width="250px"
:color="color"
>
  <v-card-title> 
  <v-avatar 
  size="48"
  tile
  >
    <v-img
      src="../../assets/embryos.png"
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
  import InputSampleID from "../Inputs/InputSampleID.vue";
  import InputGender from "../Inputs/InputGender.vue";
  import InputInformativeIDs from "../Inputs/InputInformativeIDs.vue";
  import InputHeteroIDs from "../Inputs/InputHeteroIDs.vue";
  import InputAffected from "../Inputs/InputAffected.vue";

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
      },
      color: function(){
        var diseaseStatus = this.diseaseStatus;
        if (diseaseStatus=="affected"){
          return "rgba(255,0,0,0.1)";
        }
        else if (diseaseStatus=="nonaffected"){
          return "rgba(0,255,0,0.1)";
        }
        else if (diseaseStatus=="NA"){
          return "rgba(0,0,255,0.1)";
        }
        else if (diseaseStatus=="carrier"){
          return "rgba(255,255,0,0.1)";
        }
        return "";
      },
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