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
      Config File
    </v-tab>
    
    <v-tab-item>
      <TabPedigree v-model="configPedigree" />
    </v-tab-item>
    <v-tab-item>
      <TabParameters v-model="configParameters" />
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
  import TabConfigFile from "../Tabs/TabConfigFile.vue";

  export default Vue.extend({
    name: 'Form',
    components: {
      TabPedigree,
      TabParameters,
      TabConfigFile,
    },
    data: function() {
      return {
        tab: null,
        configPedigree:{
          configGrandParentsMaternal: {"maternalGrandfather": null, "maternalGrandmother": null},
          configGrandParentsPaternal: {"paternalGrandfather": null, "paternalGrandmother": null},
          configParents: {"father": null, "mother": null},
          configSiblings: [],
          configEmbryos: [],
        },
        configParameters: {
          fileVCF:"/path/to/file.vcf",
          fileCytoband:"/path/to/cytoBand_hg38.txt",
          regions:[],
          disease: "",
          inheritance: "AD",
        },
      }
    },
    computed:{
      config: function(){
        return {
          configPedigree: this.configPedigree,
          configParameters: this.configParameters,
        };
      }
    },
  })
</script>