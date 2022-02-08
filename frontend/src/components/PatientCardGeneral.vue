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
  <v-card-text>
    <InputSampleID v-model="sampleID" />
    <InputInformativeIDs v-model="keepInformativeIDs" />
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

  //interfaces
  interface dataLayout {
    sampleID: string;
    gender: string;
    keepInformativeIDs: boolean;
  }
  interface configLayout {
    sampleID: string;
    gender: string;
    keepInformativeIDs: boolean;
  }

  export default Vue.extend({
    name: 'PedigreeGroup',
    components: {
      InputSampleID,
      InputGender,
      InputInformativeIDs,
    },
    props:{
      value: Object,
    },
    data: function() {
      var d: dataLayout = {
        sampleID: "",
        gender: "NA",
        keepInformativeIDs: false,
      }
      return d;
    },
    computed:{
      config: function(){
        var c: configLayout = {
          sampleID: this.sampleID,
          gender: this.gender,
          keepInformativeIDs: this.keepInformativeIDs,
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