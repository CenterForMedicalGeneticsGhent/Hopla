<template>
<PedigreeGroup
    width="100%"
    imgType='embryos'
    title="embryos"
    v-model="config"
    >

  content

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";

  export default Vue.extend({
    name: 'PedigreeGroupEmbryos',
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