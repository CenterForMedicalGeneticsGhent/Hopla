<template>
<v-container>
  <Pedigree v-model="configPedigree" />
  <Parameters v-model="configParameters" />


  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue';
  import Pedigree from "../Tabs/Pedigree.vue";
  import Parameters from "../Tabs/Parameters.vue";

  export default Vue.extend({
    name: 'Form',
    components: {
      Pedigree,
      Parameters,
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