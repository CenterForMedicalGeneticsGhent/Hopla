<template>
<v-container>
  <v-row>
    
    <v-col class="d-flex justify-center align-center">
    <PedigreeGroup
    width="550px"
    imgType='grandparents1'
    title="Maternal Grandparents"
    v-model="configGrandParentsMaternal"
    >
    </PedigreeGroup>
    </v-col>

    <v-col class="d-flex justify-center align-center">
    <PedigreeGroup
    width="550px"
    imgType='grandparents2'
    title="Paternal Grandparents"
    v-model="configGrandParentsMaternal"
    >
    </PedigreeGroup>
    </v-col>
  </v-row>
  
  <v-row>
    <v-col class="d-flex justify-center align-center">
    <PedigreeGroup
    width="550px"
    imgType='parents'
    title="Parents"
    v-model="configParents"
    >
    </PedigreeGroup>
    </v-col>
  </v-row>

  <v-row>
    <v-col>
    <PedigreeGroup
    width="100%"
    imgType='siblings'
    title="Siblings"
    v-model="configSiblings"
    >
    </PedigreeGroup>  
    </v-col>
  </v-row>

  <v-row>
    <v-col>
    <PedigreeGroup
    width="100%"
    imgType='embryos'
    title="Embryos"
    v-model="configEmbryos"
    >
    </PedigreeGroup>
    </v-col>
  </v-row>

</v-container>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";

  export default Vue.extend({
    name: 'Pedigree',
    components:{
      PedigreeGroup,
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