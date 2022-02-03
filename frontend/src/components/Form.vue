<template>
  <v-card>
    <v-card-title class="text-center justify-center py-6">
      <h1 class="font-weight-bold text-h2">
        HOPLA 
      </h1>
    </v-card-title>

    <v-tabs
      v-model="tab"
      grow
    >
      <v-tab
        v-for="item in items"
        :key="item.tabName"
      >
        {{ item.tabName }}
      </v-tab>
    </v-tabs>

    <v-tabs-items v-model="tab">
      <v-tab-item
        v-for="item in items"
        :key="item.tabName"
      >
        <v-card
          flat
        >
          <component 
          :is="item.subForm"
          v-model="config"
          />
        </v-card>
      </v-tab-item>
    </v-tabs-items>
  </v-card>
</template>

<script lang="ts">
  import Vue from 'vue'
  import FormStandard from './FormStandard.vue';
  import FormSingleParent from './FormSingleParent.vue';
  import FormDenovo from './FormDenovo.vue';

  export default Vue.extend({
    name: 'Form',
    components: {
      FormStandard,
      FormSingleParent,
      FormDenovo,
    },
    data: function() {
      return {
        tab: null,
        config:{
          mandatory:{
            vcfFile:"",
            sampleIDs:"",
          },
          optionalImportant:{
            fatherIDs:"",
            motherIDs:"",
            genders:"",
            cytobandFile:"/home/projects/coPGT-M/ref/cytoBand_hg38.txt",
          },
          optionalVariantInclusionFilter1:{
            dpHardLimitIDs:"",
            afHardLimitIDs:"",
            afHardLimit:0.25,
            dpSoftLimitIDs:"",
          },
          optionalVariantInclusionFilter2:{
            keepInformativeIDs:"",
            keepHeteroIDs:"",
          },
          optionalSampleDiseaseAnnotation:{
            regions:"",
            referenceIDs:"",
            carrierIDs:"",
            affectedIDs:"",
            nonAffectedIDs:"",
            disease:"",
            inheritance:"",
            sequencingNote:"",
          },
          optionalBAlleleFrequencyProfiles:{
            bafIDs:"",
          },
          optionalMerlinProfiles:{
            windowSizeVoting:"",
            keepChromosomesOnly:true,
            keepRegionsOnly:false,
          },
          optionalRemainingFeatures:{
            famID:"",
            limitBafToP:false,
            limitPmToP:true,
            valueOfP:0.15,
            selfContained:true,
            regionsFlankingSize:"",
          },
        },
        items: [
          {'tabName':'Standard', 'subForm':'FormStandard'},
          {'tabName':'Single Parent', 'subForm':'FormSingleParent'}, 
          {'tabName':'Denovo', 'subForm':'FormDenovo'},
        ],
      }
    },
  })
</script>