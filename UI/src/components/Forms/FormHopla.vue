<template>
<v-card
>
  <v-card-title>
    HOPLA
  </v-card-title>
  <v-row>
    <v-col />
    <v-col>
      <InputUploadConfig
      @updateConfig="updateConfig"
      />
    </v-col>
    <v-col />
  </v-row>
  <v-tabs 
  align-tabs="end"
  height="55"
  v-model="tab"
  >
    <v-tab value="pedigree">
      Pedigree
    </v-tab>
    <v-tab value="parameters">
      Parameters
    </v-tab>
    <v-tab value="advanced">
      Advanced
    </v-tab>
    <v-tab value="config">
      Config
    </v-tab>
  </v-tabs>
  <v-window v-model="tab">
    <v-window-item value="pedigree">
      <TabPedigree v-model="configPedigree"/>
    </v-window-item>
    <v-window-item value="parameters">
      <TabParameters v-model="configParameters" />
    </v-window-item>
    <v-window-item value="advanced">
      <TabAdvanced v-model="configAdvanced" />
    </v-window-item>
    <v-window-item value="config">
      <TabConfigFile 
      :configPedigree="configPedigree" 
      :configParameters="configParameters"
      :configAdvanced="configAdvanced"
      />
    </v-window-item>
  </v-window>
</v-card>
</template>

<script>
  import cloneDeep from 'lodash/cloneDeep';

  // Components
  import TabPedigree from "../Tabs/TabPedigree.vue";
  import TabParameters from "../Tabs/TabParameters.vue";
  import TabAdvanced from "../Tabs/TabAdvanced.vue";
  import TabConfigFile from "../Tabs/TabConfigFile.vue";
  import InputUploadConfig from "../Inputs/InputUploadConfig.vue";

  // Templates
  import {
    templatePedigree,
    templateParameters,
    templateAdvanced,
  } from "../Templates";

  export default {
    name: 'Form',
    components: {
      TabPedigree,
      TabParameters,
      TabAdvanced,
      TabConfigFile,
      InputUploadConfig,
    },
    data: function() {
      return {
        tab: "pedigree",
        configPedigree: cloneDeep(templatePedigree),
        configParameters: cloneDeep(templateParameters),
        configAdvanced:cloneDeep(templateAdvanced),
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
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
      }
    },
    methods: {
      updateConfig: function(newConfig){
        
        this.configPedigree = newConfig.configPedigree;
        this.configParameters = newConfig.configParameters;
        this.configAdvanced = newConfig.configAdvanced;        
      }
    },
    watch:{
      configWatcher:{
        handler: function(newVal,oldVal){
          if (oldVal != newVal){
            //code
          }
        },
        deep:false,
        immediate:false,
      },
    },  
  }
</script>
