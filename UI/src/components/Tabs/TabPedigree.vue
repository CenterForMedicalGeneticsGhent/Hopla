<template>
<v-container>
  <v-row
  align="center"
  justify="center"
  class="pb-0 pt-0"
  >
    <v-col class="justify-center align-center">
    </v-col>
    <v-col class="justify-center align-center">
      <InputFamilyID v-model="famID"/>
    </v-col>
    <v-col class="justify-center align-center">
    </v-col>
  </v-row>
  <v-row
  class="pb-0 pt-0"
  >
    <v-col class="d-flex justify-center align-center">
      <PedigreeGroupGrandparentsPaternal v-model="configGrandParentsPaternal"/>
    </v-col>
    
    <v-col class="d-flex justify-center align-center">
      <PedigreeGroupGrandparentsMaternal v-model="configGrandParentsMaternal"/>
    </v-col>
  </v-row>
  
  <v-row>
    <v-col class="d-flex justify-center align-center">
      <PedigreeGroupParents v-model="configParents"/>
    </v-col>
  </v-row>

  <v-row>
    <v-col>
      <PedigreeGroupSiblings v-model="configSiblings"/>
    </v-col>
  </v-row>

  <v-row>
    <v-col>
      <PedigreeGroupEmbryos v-model="configEmbryos"/>
    </v-col>
  </v-row>
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'
  import InputFamilyID from "../Inputs/InputFamilyID.vue";
  import PedigreeGroupGrandparentsPaternal from "../PedigreeGroups/PedigreeGroupGrandparentsPaternal.vue";
  import PedigreeGroupGrandparentsMaternal from "../PedigreeGroups/PedigreeGroupGrandparentsMaternal.vue";
  import PedigreeGroupParents from "../PedigreeGroups/PedigreeGroupParents.vue";
  import PedigreeGroupSiblings from "../PedigreeGroups/PedigreeGroupSiblings.vue";
  import PedigreeGroupEmbryos from "../PedigreeGroups/PedigreeGroupEmbryos.vue";


  export default Vue.extend({
    name: 'TabPedigree',
    components:{
      InputFamilyID,
      PedigreeGroupGrandparentsPaternal,
      PedigreeGroupGrandparentsMaternal,
      PedigreeGroupParents,
      PedigreeGroupSiblings,
      PedigreeGroupEmbryos,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        famID: this.value.famID,
        configGrandParentsMaternal: this.value.configGrandParentsMaternal,
        configGrandParentsPaternal: this.value.configGrandParentsPaternal,
        configParents: this.value.configParents,
        configSiblings: this.value.configSiblings,
        configEmbryos: this.value.configEmbryos,
      }
    },
    computed:{
      config: function(){
        return {
          famID: this.famID,
          configGrandParentsMaternal: this.configGrandParentsMaternal,
          configGrandParentsPaternal: this.configGrandParentsPaternal,
          configParents: this.configParents,
          configSiblings: this.configSiblings,
          configEmbryos: this.configEmbryos,
        };
      },
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
      },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      }
    },
    watch:{
      configWatcher:{
        handler: function(newVal,oldVal){
          if (oldVal != newVal){
            this.handleInput();
          }
        },
        deep:false,
        immediate:false,
      },
    },  
    })
</script>