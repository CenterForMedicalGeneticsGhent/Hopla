<template>
<v-card>
  <v-tabs right>

    <v-card-title>
      HOPLA
    </v-card-title>
    <v-spacer />
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
      <TabConfigFile :config="config" />
    </v-tab-item>
    
  </v-tabs>
</v-card>
</template>

<script>
  import Vue from 'vue';
  import TabPedigree from "../Tabs/TabPedigree.vue";
  import TabParameters from "../Tabs/TabParameters.vue";
  import TabAdvanced from "../Tabs/TabAdvanced.vue";
  import TabConfigFile from "../Tabs/TabConfigFile.vue";

  export default Vue.extend({
    name: 'Form',
    components: {
      TabPedigree,
      TabParameters,
      TabAdvanced,
      TabConfigFile,
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
          fileCytoband:"/path/to/cytoBand_hg38.txt",
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