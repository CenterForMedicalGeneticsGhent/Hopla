<template>
<v-card
width="220px"
:color="color"
>
  <v-card-title class="text-subtitle-1"> 
  <v-avatar
  density="compact"
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
  density="compact"
  class=""
  >
    <InputSampleID v-model="config.sampleID" />
    <InputKeepLimitIDHardDP v-model="config.keepLimitIDHardDP" v-if="config.keepLimitIDHardDP!='hide'"/>
    <InputKeepLimitIDHardAF v-model="config.keepLimitIDHardAF" v-if="config.keepLimitIDHardAF!='hide'"/>
    <InputKeepLimitIDSoftDP v-model="config.keepLimitIDSoftDP" v-if="config.keepLimitIDSoftDP!='hide'"/>
    <InputInformativeIDs v-model="config.keepInformativeIDs" v-if="config.keepInformativeIDs!='hide'"/>
    <InputBafIDs v-model="config.keepBafIDs" v-if="config.keepBafIDs!='hide'"/>
    <InputAffected v-model="config.diseaseStatus" />
    <v-btn
    density="compact"
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
  import InputSampleID from "../Inputs/InputSampleID.vue";
  import InputGender from "../Inputs/InputGender.vue";
  import InputInformativeIDs from "../Inputs/InputInformativeIDs.vue";
  import InputAffected from "../Inputs/InputAffected.vue";
  import InputKeepLimitIDHardDP from "../Inputs/InputKeepLimitIDHardDP.vue";
  import InputKeepLimitIDHardAF from "../Inputs/InputKeepLimitIDHardAF.vue";
  import InputKeepLimitIDSoftDP from "../Inputs/InputKeepLimitIDSoftDP.vue";
  import InputBafIDs from "../Inputs/InputBafIDs.vue";

  import embryosImg from "../../assets/embryos.png";
  import siblingNAImg from "../../assets/siblingNA.png";
  import siblingBoyImg from "../../assets/siblingBoy.png";
  import siblingGirlImg from "../../assets/siblingGirl.png";
  import fatherImg from "../../assets/father.png";
  import motherImg from "../../assets/mother.png";
  import paternalGrandfatherImg from "../../assets/paternalGrandfather.png";
  import paternalGrandmotherImg from "../../assets/paternalGrandmother.png";
  import maternalGrandfatherImg from "../../assets/maternalGrandfather.png";
  import maternalGrandmotherImg from "../../assets/maternalGrandmother.png";

  export default {
    name: 'PatientCardGeneral',
    emits: ['update:modelValue', 'removeCard'],
    components: {
      InputSampleID,
      InputKeepLimitIDHardDP,
      InputKeepLimitIDHardAF,
      InputKeepLimitIDSoftDP,
      InputGender,
      InputInformativeIDs,
      InputBafIDs,
      InputAffected,
    },
    props:{
      modelValue: Object,
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
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
          return embryosImg;
        }
        else if (cardType=="siblingNA"){
          return siblingNAImg;
        }
        else if (cardType=="siblingBoy"){
          return siblingBoyImg;
        }
        else if (cardType=="siblingGirl"){
          return siblingGirlImg;
        }
        else if (cardType=="father"){
          return fatherImg;
        }
        else if (cardType=="mother"){
          return motherImg;
        }
        else if (cardType=="paternalGrandfather"){
          return paternalGrandfatherImg;
        }
        else if (cardType=="paternalGrandmother"){
          return paternalGrandmotherImg;
        }
        else if (cardType=="maternalGrandfather"){
          return maternalGrandfatherImg;
        }
        else if (cardType=="maternalGrandmother"){
          return maternalGrandmotherImg;
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
  }
</script>
