<template>
<v-container>
  <OutputDownloadConfig 
  :fileNameDefault="configPedigree.famID+'.txt'" 
  :textToDownload="configText" 
  />
  <pre id="config_text">{{configText}}</pre>
</v-container>
</template>

<script>
import Vue from 'vue'

// Components
import OutputDownloadConfig from "../Outputs/OutputDownloadConfig.vue";

// Parsers
import {
  parseSampleIDs,
  parseFatherIDs,
  parseMotherIDs,
  parseGenders,
  parseDpHardLimitIDs,
  parseAfHardLimitIDs,
  parseDpSoftLimitIDs,
  parseKeepInformativeIDs,
  parseKeepHeteroIDs,
  parseCarrierIDs,
  parseAffectedIDs,
  parseNonAffectedIDs,
  parseBafIDs,
} from "../Parsers/Form2Config";

export default Vue.extend({
  name: 'TabConfigFile',
  components:{
    OutputDownloadConfig,
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
      return ""
        + this.sectionPedigreeInfo
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

    sectionPedigreeInfo: function(){
      return  this.sectionPedigreeInfoTitle
            + this.sectionPedigreePaternalGrandfather
            + this.sectionPedigreePaternalGrandmother
            + this.sectionPedigreeMaternalGrandfather
            + this.sectionPedigreeMaternalGrandmother
            + this.sectionPedigreeFather
            + this.sectionPedigreeMother
            + this.sectionPedigreeSiblings
            + this.sectionPedigreeEmbryos
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
            + this.sectionRemainingFeaturesSelfContained
            + this.sectionRemainingFeaturesRegionsFlankingSize
            ;
    },


    sectionPedigreeInfoTitle: function(){
      return  "# ------\n"
            + "# HEADER\n"
            + "# ------\n"
            ;        
    },
    sectionPedigreePaternalGrandfather: function(){
      return  "# paternalGrandfather="
            + this.configPedigree.configGrandParentsPaternal.paternalGrandfather.sampleID
            + "\n"
            ;
    },
    sectionPedigreePaternalGrandmother: function(){
      return  "# paternalGrandmother="
            + this.configPedigree.configGrandParentsPaternal.paternalGrandmother.sampleID
            + "\n"
            ;
    },
    sectionPedigreeMaternalGrandfather: function(){
      return  "# maternalGrandfather="
            + this.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID
            + "\n"
            ;
    },
    sectionPedigreeMaternalGrandmother: function(){
      return  "# maternalGrandmother="
            + this.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID
            + "\n"
            ;
    },
    sectionPedigreeFather: function(){
      return  "# father="
            + this.configPedigree.configParents.father.sampleID
            + "\n"
            ;
    },
    sectionPedigreeMother: function(){
      return  "# mother="
            + this.configPedigree.configParents.mother.sampleID
            + "\n"
            ;
    },
    sectionPedigreeSiblings: function(){
      return  "# siblings="
            + this.configPedigree.configSiblings.map(function(d){return d.sampleID}).toString()
            + "\n"
            ;
    },
    sectionPedigreeEmbryos: function(){
      return  "# embryos="
            + this.configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID}).toString()
            + "\n"
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
      return  "value.of.P="
            + this.configAdvanced.remainingFeatures.valueOfP
            + "\n"
            ;
    },
    sectionRemainingFeaturesSelfContained: function(){
      if (this.configAdvanced.remainingFeatures.selfContained===true){
        return "self.contained=T\n";
      }
      else {
        return "self.contained=F\n";
      }
    },
    sectionRemainingFeaturesRegionsFlankingSize: function(){
      return  "regions.flanking.size="
            + this.configAdvanced.remainingFeatures.regionsFlankingSize
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
