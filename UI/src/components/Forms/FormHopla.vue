<template>
<v-card>
  <v-tabs 
  right
  height=55
  >

    <v-card-title>
      HOPLA
    </v-card-title>
    <v-row>
      <v-col />
      <v-col>
        <!--<InputUploadConfig />-->
      </v-col>
      <v-col />
    </v-row>
    <v-tab>
      Pedigree
    </v-tab>
    <v-tab>
      Parameters
    </v-tab>
    <v-tab>
      Advanced
    </v-tab>
    <v-tab>
      Config
    </v-tab>
    
    <v-tab-item>
      <TabPedigree v-model="configPedigree" />
    </v-tab-item>
    <v-tab-item>
      <TabParameters v-model="configParameters" />
    </v-tab-item>
    <v-tab-item>
      <TabAdvanced v-model="configAdvanced" />
    </v-tab-item>
    <v-tab-item>
      <TabConfigFile 
      :configPedigree="configPedigree" 
      :configParameters="configParameters"
      :configAdvanced="configAdvanced"
      />
    </v-tab-item>
    
  </v-tabs>
</v-card>
</template>

<script>
  import Vue from 'vue';
  import cloneDeep from 'lodash/cloneDeep';
  import TabPedigree from "../Tabs/TabPedigree.vue";
  import TabParameters from "../Tabs/TabParameters.vue";
  import TabAdvanced from "../Tabs/TabAdvanced.vue";
  import TabConfigFile from "../Tabs/TabConfigFile.vue";
  import InputUploadConfig from "../Inputs/InputUploadConfig.vue";

  export default Vue.extend({
    name: 'Form',
    components: {
      TabPedigree,
      TabParameters,
      TabAdvanced,
      TabConfigFile,
      //InputUploadConfig,
    },
    data: function() {
      return {
        tab: null,
        configPedigree:{
          famID: "",
          configGrandParentsMaternal: {"maternalGrandfather": null, "maternalGrandmother": null},
          configGrandParentsPaternal: {"paternalGrandfather": null, "paternalGrandmother": null},
          configParents: {"father": null, "mother": null},
          configSiblings: [],
          configEmbryos: {
            embryoList: [],
            keepHeteroIDs: false,
          },
        },
        configParameters: {
          fileVCF:"/path/to/file.vcf",
          fileCytoband:"/home/projects/coPGT-M/ref/cytoBand_hg38.txt",
          afHardLimit: 0.25,
          sampleDisease:{
            regions:[],
            disease: "",
            inheritance: "AD",
            sequencingNote:"",
          },
          merlinProfiles:{
            windowSizeVoting: 10000000,
            keepChromosomesRegionsOnly:{
              keepChromosomesOnly:false,
              keepRegionsOnly:false,
            }
          }
        },
        configAdvanced:{
          remainingFeatures: {
            limitPmToP: true,
            valueOfP: 0.15,
            limitBafToP: false,
            selfContained: true,
            regionsFlankingSize: 1000000,
          },
        },
      }
    },
    computed:{
      config: {
        get: function(){
          return {
            configPedigree: this.configPedigree,
            configParameters: this.configParameters,
            configAdvanced: this.configAdvanced,
          };
        },
      },
    },
  })
</script>
