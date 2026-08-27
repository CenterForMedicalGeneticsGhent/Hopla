<template>
<v-container>
  <OutputDownloadConfig
  :fileNameDefault="configPedigree.famID+'.yaml'"
  :textToDownload="configText"
  />
  <pre>{{configText}}</pre>
</v-container>
</template>

<script>

// Components
import OutputDownloadConfig from "../Outputs/OutputDownloadConfig.vue";

// Parsers
import { form2SettingsYaml } from "../Parsers/Form2Settings";

export default {
  name: "TabConfigFile",
  components: {
    OutputDownloadConfig,
  },
  props: {
    configPedigree: Object,
    configParameters: Object,
    configAdvanced: Object,
  },
  computed: {
    configText: function() {
      return form2SettingsYaml(
        this.configPedigree,
        this.configParameters,
        this.configAdvanced,
      );
    },
  },
};
</script>
