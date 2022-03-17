<template>
<v-container
>
  <v-row
  align="center"
  justify="center"
  class="pb-0 pt-0"
  >
    <v-col class="justify-center align-center">
    </v-col>
    <v-col class="justify-center align-center">
      <InputFamilyID v-model="config.famID"/>
    </v-col>
    <v-col class="justify-center align-center">
    </v-col>
  </v-row>
  <v-row
  class="pb-0 pt-0"
  >
    <v-col class="d-flex justify-center align-center">
      <PedigreeGroupGrandparentsPaternal v-model="config.configGrandParentsPaternal"/>
    </v-col>
    
    <v-col class="d-flex justify-center align-center">
      <PedigreeGroupGrandparentsMaternal v-model="config.configGrandParentsMaternal"/>
    </v-col>
  </v-row>
  
  <v-row>
    <v-col class="d-flex justify-center align-center">
      <PedigreeGroupParents v-model="config.configParents"/>
    </v-col>
  </v-row>

  <v-row>
    <v-col>
      <PedigreeGroupSiblings v-model="config.configSiblings"/>
    </v-col>
  </v-row>

  <v-row>
    <v-col>
      <PedigreeGroupEmbryos v-model="config.configEmbryos"/>
    </v-col>
  </v-row>
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
    data: function(){
      return {
      }
    },
    computed:{
      config: {
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        }
      },
    },
    methods:{
    },
    watch:{
    },  
    })
</script>