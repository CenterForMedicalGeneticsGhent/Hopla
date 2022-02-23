<template>
<PatientCardGeneral
v-model="config"
:title="title"
cardType="embryo"
@removeCard="removeCard()"
:genderLocked="false"
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
      i: Number,
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
      title: function(){
        return `Embryo ${this.i+1}`;
      },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      },
      removeCard:function(){
        this.$emit('removeCard');
      }
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