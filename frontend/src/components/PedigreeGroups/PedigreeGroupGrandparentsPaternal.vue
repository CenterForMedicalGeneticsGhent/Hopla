<template>
<PedigreeGroup
    width="550px"
    imgType='grandparents1'
    title="Paternal Grandparents"
    v-model="config"
    :addBtn="false"
    >

  content

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";

  export default Vue.extend({
    name: 'PedigreeGroupGrandparentsPaternal',
    components:{
      PedigreeGroup,
    },
    props:{
      value: Array,
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