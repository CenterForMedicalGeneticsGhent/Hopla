<template>
<PedigreeGroup
    width="550px"
    imgType='parents'
    title="Parents"
    v-model="config"
    :addBtn="false"
    >

  {{ config }}

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";

  export default Vue.extend({
    name: 'PedigreeGroupParents',
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