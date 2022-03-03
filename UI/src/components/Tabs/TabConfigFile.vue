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
import {parseKeepInformativeIDs} from "../Parsers/ParseKeepInformativeIDs";
import {parseKeepHeteroIDs} from "../Parsers/ParseKeepHeteroIDs";
import {parseCarrierIDs} from "../Parsers/ParseCarrierIDs";
import {parseAffectedIDs} from "../Parsers/ParseAffectedIDs";
import {parseNonAffectedIDs} from "../Parsers/ParseNonAffectedIDs";
import {parseBafIDs} from "../Parsers/ParseBafIDs";



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
            + this.sectionVariantInclusionFilter2KeepInformativeIDs
            + this.sectionVariantInclusionFilter2KeepHeteroIDs
            ;
    },
    sectionSampleDiseaseAnnotation: function(){
      return  this.sectionSampleDiseaseAnnotationTitle
            + this.sectionSampleDiseaseAnnotationRegions
            + this.sectionSampleDiseaseAnnotationReferenceIDs
            + this.sectionSampleDiseaseAnnotationCarrierIDs
            + this.sectionSampleDiseaseAnnotationAffectedIDs
            + this.sectionSampleDiseaseAnnotationNonAffectedIDs
            + "start.info\n"
            + this.sectionSampleDiseaseAnnotationDisease
            + this.sectionSampleDiseaseAnnotationInheritance
            + this.sectionSampleDiseaseAnnotationSequencingNote
            + "end.info\n"
            ;
    },
    sectionBAlleleFrequencyProfiles: function(){
      return  this.sectionBAlleleFrequencyProfilesTitle
            + this.sectionBAlleleFrequencyProfilesBafIDs
            ;
    },
    sectionMerlinProfiles: function(){
      return  this.sectionMerlinProfilesTitle
            + this.sectionMerlinProfilesWindowSizeVoting
            + this.sectionMerlinProfilesKeepChromosomesOnly
            + this.sectionMerlinProfilesKeepRegionsOnly
            ;
    },
    sectionRemainingFeatures: function(){
      return  this.sectionRemainingFeaturesTitle
            + this.sectionRemainingFeaturesFamilyID
            + this.sectionRemainingFeaturesLimitBafToP
            + this.sectionRemainingFeaturesLimitPmToP
            + this.sectionRemainingFeaturesValueOfP
            ;
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
    sectionVariantInclusionFilter2KeepInformativeIDs: function(){
      return  "keep.informative.ids="
            + parseKeepInformativeIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionVariantInclusionFilter2KeepHeteroIDs: function(){
      return  "keep.hetero.ids="
            + parseKeepHeteroIDs(this.configPedigree)
            + "\n"
            ;
    },


    sectionSampleDiseaseAnnotationTitle: function(){
      return  "# -----------------------------------\n"
            + "# OPTIONAL: SAMPLE/DISEASE ANNOTATION\n"
            + "# -----------------------------------\n"
            ;
    },
    sectionSampleDiseaseAnnotationRegions: function(){
      let regions = this.configParameters.sampleDisease.regions;
      if (regions.length>0){
        return  "regions="
            + `${regions[0].chr}:${regions[0].chrStart}-${regions[0].chrEnd}`
            + "\n"
            ;
      }
      else {
        return "regions="
              + "\n"
              ;
      }
    },
    sectionSampleDiseaseAnnotationReferenceIDs: function(){
      return  "reference.ids="
            + "\n"
            ;
    },
    sectionSampleDiseaseAnnotationCarrierIDs: function(){
      return  "carrier.ids="
            + parseCarrierIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionSampleDiseaseAnnotationAffectedIDs: function(){
      return  "affected.ids="
            + parseAffectedIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionSampleDiseaseAnnotationNonAffectedIDs: function(){
      return  "nonaffected.ids="
            + parseNonAffectedIDs(this.configPedigree)
            + "\n"
            ;
    },
    sectionSampleDiseaseAnnotationDisease: function(){
      return  "Disease:"
            + this.configParameters.sampleDisease.disease
            + "\n"
            ;
    },
    sectionSampleDiseaseAnnotationInheritance: function(){
      return  "Inheritance:"
            + this.configParameters.sampleDisease.inheritance
            + "\n"
            ;
    },
    sectionSampleDiseaseAnnotationSequencingNote: function(){
      return  "Sequencing note:"
            + this.configParameters.sampleDisease.sequencingNote
            + "\n"
            ;
    },


    sectionBAlleleFrequencyProfilesTitle: function(){
      return  "# -------------------------------------\n"
            + "# OPTIONAL: B-ALLELE FREQUENCY PROFILES\n"
            + "# -------------------------------------\n"
            ;
    },
    sectionBAlleleFrequencyProfilesBafIDs: function(){
      return  "baf.ids="
            + parseBafIDs(this.configPedigree)
            + "\n"
            ;
    },


    sectionMerlinProfilesTitle: function(){
      return  "# -------------------------\n"
            + "# OPTIONAL: Merlin Profiles\n"
            + "# -------------------------\n"
            ;
    },
    sectionMerlinProfilesWindowSizeVoting: function(){
      return  "window.size.voting="
            + this.configParameters.merlinProfiles.windowSizeVoting
            + "\n"
            ;
    },
    sectionMerlinProfilesKeepChromosomesOnly: function(){
      if (this.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepChromosomesOnly===true){
        return "keep.chromosomes.only=T\n";
      }
      else {
        return "keep.chromosomes.only=F\n";
      }
    },
    sectionMerlinProfilesKeepRegionsOnly: function(){
      if (this.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepRegionsOnly===true){
        return "keep.regions.only=T\n";
      }
      else {
        return "keep.regions.only=F\n";
      } 
    },


    sectionRemainingFeaturesTitle: function(){
      return  "# ----------------------------\n"
            + "# OPTIONAL: REMAINING FEATURES\n"
            + "# ----------------------------\n"
            ;

    },
    sectionRemainingFeaturesFamilyID: function(){
      return  "fam.id="
            + this.configPedigree.famID
            + "\n"
            ;

    },
    sectionRemainingFeaturesLimitBafToP: function(){
      if (this.configAdvanced.remainingFeatures.limitBafToP===true){
        return "limit.baf.to.P=T\n";
      }
      else {
        return "limit.baf.to.P=F\n";
      } 
    },
    sectionRemainingFeaturesLimitPmToP: function(){
      if (this.configAdvanced.remainingFeatures.limitPmToP===true){
        return "limit.pm.to.P=T\n";
      }
      else {
        return "limit.pm.to.P=F\n";
      } 
    },
    sectionRemainingFeaturesValueOfP: function(){
      return  "value.of.p="
            + this.configAdvanced.remainingFeatures.valueOfP
            + "\n"
            ;
    },

  },
  methods:{
  },
  watch:{
  },  
})
</script>