<template>
<v-container>
  <v-row>
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
</v-container>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PedigreeGroupGrandparentsPaternal from "./PedigreeGroupGrandparentsPaternal.vue";
  import PedigreeGroupGrandparentsMaternal from "./PedigreeGroupGrandparentsMaternal.vue";
  import PedigreeGroupParents from "./PedigreeGroupParents.vue";
  import PedigreeGroupSiblings from "./PedigreeGroupSiblings.vue";
  import PedigreeGroupEmbryos from "./PedigreeGroupEmbryos.vue";


  export default Vue.extend({
    name: 'Pedigree',
    components:{
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
        config: this.value,
        configGrandParentsMaternal: null,
        configGrandParentsPaternal: null,
        configParents: null,
        configSiblings: null,
        configEmbryos: null,
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      }
    },  
    })
</script>