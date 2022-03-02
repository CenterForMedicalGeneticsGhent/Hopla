<template>
<pre> 
  {{configText}}
</pre>
</template>

<script>
import Vue from 'vue'

import {parseSampleIDs} from "../Parsers/ParseSampleIDs";



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
      return `vcf.file=${this.configParameters.fileVCF}\n`;
    },
    sectionMandatorySampleIDs: function(){
      return `sample.ids=${parseSampleIDs(this.configPedigree)}\n`
    },

    sectionImportantTitle: function(){
      return  "# ----------------------------\n"
            + "# IMPORTANT OPTIONAL ARGUMENTS\n"
            + "# ----------------------------\n"
            ;
    }
  },
  methods:{
  },
  watch:{
  },  
})
</script>