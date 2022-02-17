<template>
<v-card
width="220px"
:color="color"
>
  <v-card-title class="text-subtitle-1"> 
  <v-avatar
  dense 
  size="40"
  tile
  >
    <v-img
      :src="imgSrc"
    />
  </v-avatar>
  <v-spacer />
  {{title}}
  <v-spacer />
   <InputGender v-model="gender" :genderLocked="genderLocked" />
  </v-card-title>
  <v-card-text
  dense
  class=""
  >
    <InputSampleID v-model="sampleID" />
    <InputKeepLimitIDHardDP v-model="keepLimitIDHardDP" v-if="keepLimitIDHardDP!='hide'"/>
    <InputKeepLimitIDHardAF v-model="keepLimitIDHardAF" v-if="keepLimitIDHardAF!='hide'"/>
    <InputKeepLimitIDSoftDP v-model="keepLimitIDSoftDP" v-if="keepLimitIDSoftDP!='hide'"/>
    <InputInformativeIDs v-model="keepInformativeIDs" v-if="keepInformativeIDs!='hide'"/>
    <InputAffected v-model="diseaseStatus" />
    <v-btn
    dense
    depressed
    color="error"
    @click="removeCard()"
    >
      Remove
    </v-btn>
  </v-card-text>
</v-card>
</template>

<script>
  // Imports
  import Vue from 'vue'
  import InputSampleID from "../Inputs/InputSampleID.vue";
  import InputGender from "../Inputs/InputGender.vue";
  import InputInformativeIDs from "../Inputs/InputInformativeIDs.vue";
  import InputAffected from "../Inputs/InputAffected.vue";
  import InputKeepLimitIDHardDP from "../Inputs/InputKeepLimitIDHardDP.vue";
  import InputKeepLimitIDHardAF from "../Inputs/InputKeepLimitIDHardAF.vue";
  import InputKeepLimitIDSoftDP from "../Inputs/InputKeepLimitIDSoftDP.vue";

  export default Vue.extend({
    name: 'PatientCardGeneral',
    components: {
      InputSampleID,
      InputKeepLimitIDHardDP,
      InputKeepLimitIDHardAF,
      InputKeepLimitIDSoftDP,
      InputGender,
      InputInformativeIDs,
      InputAffected,
    },
    props:{
      value: Object,
      title: String,
      cardType: String,
      genderLocked:Boolean,
    },
    data: function() {
      var d = {
        sampleID: this.value.sampleID,
        gender: this.value.gender,
        keepInformativeIDs: this.value.keepInformativeIDs,
        diseaseStatus: this.value.diseaseStatus,
        keepLimitIDHardDP: this.value.keepLimitIDHardDP,
        keepLimitIDHardAF: this.value.keepLimitIDHardAF,
        keepLimitIDSoftDP: this.value.keepLimitIDSoftDP,
      }
      return d;
    },
    computed:{
      config: function(){
        var c = {
          sampleID: this.sampleID,
          gender: this.gender,
          keepInformativeIDs: this.keepInformativeIDs,
          diseaseStatus: this.diseaseStatus,
          keepLimitIDHardDP: this.keepLimitIDHardDP,
          keepLimitIDHardAF: this.keepLimitIDHardAF,
          keepLimitIDSoftDP: this.keepLimitIDSoftDP,
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
        else if (cardType=="siblingNA"){
          return require("../../assets/siblingNA.png")
        }
        else if (cardType=="siblingBoy"){
          return require("../../assets/siblingBoy.png")
        }
        else if (cardType=="siblingGirl"){
          return require("../../assets/siblingGirl.png")
        }
        else if (cardType=="father"){
          return require("../../assets/father.png")
        }
        else if (cardType=="mother"){
          return require("../../assets/mother.png")
        }
        else if (cardType=="paternalGrandfather"){
          return require("../../assets/paternalGrandfather.png")
        }
        else if (cardType=="paternalGrandmother"){
          return require("../../assets/paternalGrandmother.png")
        }
        else if (cardType=="maternalGrandfather"){
          return require("../../assets/maternalGrandfather.png")
        }
        else if (cardType=="maternalGrandmother"){
          return require("../../assets/maternalGrandmother.png")
        }
        return "";
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
      removeCard: function(){
        this.$emit('removeCard',null);
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