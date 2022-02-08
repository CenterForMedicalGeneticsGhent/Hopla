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
      :src="imgSrc"
    />
  </v-avatar>
  <v-spacer />
  {{title}}
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

<script>
  // Imports
  import Vue from 'vue'
  import InputSampleID from "../Inputs/InputSampleID.vue";
  import InputGender from "../Inputs/InputGender.vue";
  import InputInformativeIDs from "../Inputs/InputInformativeIDs.vue";
  import InputHeteroIDs from "../Inputs/InputHeteroIDs.vue";
  import InputAffected from "../Inputs/InputAffected.vue";

  export default Vue.extend({
    name: 'PatientCardGeneral',
    components: {
      InputSampleID,
      InputGender,
      InputInformativeIDs,
      InputHeteroIDs,
      InputAffected,
    },
    props:{
      value: Object,
      title: String,
      cardType: String,
    },
    data: function() {
      var d = {
        sampleID: this.value.sampleID,
        gender: this.value.gender,
        keepInformativeIDs: this.value.keepInformativeIDs,
        keepHeteroIDs: this.value.keepHeteroIDs,
        diseaseStatus: this.value.diseaseStatus,
      }
      return d;
    },
    computed:{
      config: function(){
        var c = {
          sampleID: this.sampleID,
          gender: this.gender,
          keepInformativeIDs: this.keepInformativeIDs,
          keepHeteroIDs: this.keepHeteroIDs,
          diseaseStatus: this.diseaseStatus,
        }
        return c;
      },
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
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
      imgSrc: function(){
        var cardType=this.cardType;
        if (cardType=="embryo"){
          return require("../../assets/embryos.png")
        }
        return "";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
    },
    mounted: function(){
      //CODE
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