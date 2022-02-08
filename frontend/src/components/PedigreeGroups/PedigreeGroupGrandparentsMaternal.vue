<template>
<PedigreeGroup
    width="550px"
    imgType='grandparents2'
    title="Maternal Grandparents"
    v-model="config"
    >

  content

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";

  export default Vue.extend({
    name: 'PedigreeGroupGrandparentsMaternal',
    components:{
      PedigreeGroup,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: this.value,
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
    },
    mounted: function(){
      //CODE
    }  
    })
</script>