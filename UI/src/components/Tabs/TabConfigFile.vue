<template>
<v-container>
  <pre> 
    {{configText}}
  </pre>
</v-container>
</template>

<script>
import Vue from 'vue'

import {parseSampleIDs} from "../Parsers/ParseSampleIDs";
import {parseFatherIDs} from "../Parsers/ParseFatherIDs";
import {parseMotherIDs} from "../Parsers/ParseMotherIDs";
import {parseGenders} from "../Parsers/ParseGenders";
import {parseDpHardLimitIDs}  from "../Parsers/ParseDpHardLimitIDs";
import {parseAfHardLimitIDs}  from "../Parsers/ParseAfHardLimitIDs";
import {parseDpSoftLimitIDs}  from "../Parsers/ParseDpSoftLimitIDs";



export default Vue.extend({
  name: 'TabConfigFile',
  components:{
  },
  props:{
    configPedigree: Object,
    configParameters: Object,
    configAdvanced: Object,
  },
  data: function() {
    return {
    };
  },
  computed:{
    configText: function(){
      return "\n"
        + this.sectionMandatory 
        + this.sectionImportant 
        + this.sectionVariantInclusionFilter1
        + this.sectionVariantInclusionFilter2
        + this.sectionSampleDiseaseAnnotation
        + this.sectionBAlleleFrequencyProfiles
        + this.sectionMerlinProfiles
        + this.sectionRemainingFeatures
        ;
      },


    sectionMandatory: function(){
      return  this.sectionMandatoryTitle
          +   this.sectionMandatoryVcfFile
          +   this.sectionMandatorySampleIDs
          ;
    },
    sectionImportant: function(){
      return  this.sectionImportantTitle
            + this.sectionImportantFatherIDs
            + this.sectionImportantMotherIDs
            + this.sectionImportantGenders
            + this.sectionImportantFileCytoband
            ; 
    },
    sectionVariantInclusionFilter1: function(){
      return  this.sectionVariantInclusionFilter1Title
            + this.sectionVariantInclusionFilter1DpHardLimitIDs
            + this.sectionVariantInclusionFilter1AfHardLimitIDs
            + this.sectionVariantInclusionFilter1AfHardLimit
            + this.sectionVariantInclusionFilter1DpSoftLimitIDs
            ;
    },
    sectionVariantInclusionFilter2: function(){
      return  this.sectionVariantInclusionFilter2Title
            ;
    },
    sectionSampleDiseaseAnnotation: function(){
      return "sectionSampleDiseaseAnnotation\n";
    },
    sectionBAlleleFrequencyProfiles: function(){
      return "sectionBAlleleFrequencyProfiles\n";
    },
    sectionMerlinProfiles: function(){
      return "sectionMerlinProfiles\n";
    },
    sectionRemainingFeatures: function(){
      return "sectionRemainingFeatures\n";
    },


    sectionMandatoryTitle: function(){
      return "# -------------------\n"
          +  "# MANDATORY ARGUMENTS\n"
          +  "# -------------------\n"
          ;
    },
    sectionMandatoryVcfFile: function(){
      return  "vcf.file="
            + this.configParameters.fileVCF
            + "\n"
            ;
    },
    sectionMandatorySampleIDs: function(){
      return  "sample.ids="
            + parseSampleIDs(this.configPedigree)
            + "\n"
            ;
    },


    sectionImportantTitle: function(){
      return  "# ----------------------------\n"
            + "# IMPORTANT OPTIONAL ARGUMENTS\n"
            + "# ----------------------------\n"
            ;
    },
    sectionImportantFatherIDs: function(){
      return  "father.ids="
            + parseFatherIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionImportantMotherIDs: function(){
      return  "mother.ids="
            + parseMotherIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionImportantGenders: function(){
      return  "genders="
            + parseGenders(this.configPedigree)
            + "\n"
            ;
    },
    sectionImportantFileCytoband: function(){
      return  "cytoband.file="
            + this.configParameters.fileCytoband
            + "\n"
            ;
    },


    sectionVariantInclusionFilter1Title: function(){
      return  "# --------------------------------------------------------\n"
            + "# IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 1\n"
            + "# --------------------------------------------------------\n"
            ;
    },
    sectionVariantInclusionFilter1DpHardLimitIDs: function(){
      return  "dp.hard.limit.ids="
            + parseDpHardLimitIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionVariantInclusionFilter1AfHardLimitIDs: function(){
      return  "af.hard.limit.ids="
            + parseAfHardLimitIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionVariantInclusionFilter1AfHardLimit: function(){
      return  "af.hard.limit="
            + this.configParameters.afHardLimit
            + "\n"
            ;
    },
    sectionVariantInclusionFilter1DpSoftLimitIDs: function(){
      return  "dp.soft.limit.ids="
            + parseDpSoftLimitIDs(this.configPedigree)
            + "\n"
            ;
    },


    sectionVariantInclusionFilter2Title: function(){
      return  "# --------------------------------------------------------\n"
            + "# IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 2\n"
            + "# --------------------------------------------------------\n"
            ;
    },
  },
  methods:{
  },
  watch:{
  },  
})
</script>