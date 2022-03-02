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
      return "Section VariantInclusionFilter1\n";
    },
    sectionVariantInclusionFilter2: function(){
      return "SectionVariantInclusionFilter2\n";
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
    }
  },
  methods:{
  },
  watch:{
  },  
})
</script>