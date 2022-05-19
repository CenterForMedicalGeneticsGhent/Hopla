<template>
<v-card
>
  <v-tabs 
  right
  height=55
  v-model="tab"
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
    <v-tab id="tab_pedigree">
      Pedigree
    </v-tab>
    <v-tab id="tab_parameters">
      Parameters
    </v-tab>
    <v-tab id="tab_advanced">
      Advanced
    </v-tab>
    <v-tab id="tab_config">
      Config
    </v-tab>
    
    <v-tab-item>
      <TabPedigree v-model="configPedigree"/>
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

  export default Vue.extend({
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
        tab: "Pedigree",
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
  })
</script>
