<template>
<PatientCardGeneral
v-model="config"
title="Embryo 1"
cardType="embryo"
/>
</template>

<script>
  // Imports
  import Vue from 'vue'
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  export default Vue.extend({
    name: 'PatientCardEmbryo',
    components: {
      PatientCardGeneral,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: this.value
      };
    },
    computed: {
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
      },
    },
    mounted: function(){
      //CODE
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