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
   <InputGender v-model="config.gender" :genderLocked="genderLocked" />
  </v-card-title>
  <v-card-text
  dense
  class=""
  >
    <InputSampleID v-model="config.sampleID" />
    <InputKeepLimitIDHardDP v-model="config.keepLimitIDHardDP" v-if="config.keepLimitIDHardDP!='hide'"/>
    <InputKeepLimitIDHardAF v-model="config.keepLimitIDHardAF" v-if="config.keepLimitIDHardAF!='hide'"/>
    <InputKeepLimitIDSoftDP v-model="config.keepLimitIDSoftDP" v-if="config.keepLimitIDSoftDP!='hide'"/>
    <InputInformativeIDs v-model="config.keepInformativeIDs" v-if="config.keepInformativeIDs!='hide'"/>
    <InputKeepBafProfile v-model="config.keepBafProfile" v-if="config.keepBafProfile!='hide'"/>
    <InputAffected v-model="config.diseaseStatus" />
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
  import InputKeepBafProfile from "../Inputs/InputKeepBafProfile.vue";

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
      InputKeepBafProfile,
    },
    props:{
      value: Object,
      title: String,
      cardType: String,
      genderLocked:Boolean,
    },
    data: function() {
      return {
      };
    },
    computed:{
      config: {
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        },
      },
      color: function(){
        var diseaseStatus = this.config.diseaseStatus;
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
      removeCard: function(){
        this.$emit('removeCard',null);
      },
    },
    mounted: function(){
      //CODE
    },
    watch:{
      //CODE
    },  
  })
</script>