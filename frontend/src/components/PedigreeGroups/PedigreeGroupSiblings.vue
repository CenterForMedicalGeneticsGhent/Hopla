<template>
<PedigreeGroup
    width="100%"
    imgType='siblings'
    title="Siblings"
    v-model="config"
    :addBtn="true"
    >

  content

</PedigreeGroup>
</template>

<script lang="ts">
  import Vue from 'vue'
  import PedigreeGroup from "./PedigreeGroup.vue";

  export default Vue.extend({
    name: 'PedigreeGroupSiblings',
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