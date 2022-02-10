<template>
<PatientCardGeneral
v-model="config"
:title="title"
:cardType="cardType"
@removeCard="removeCard()"
:genderLocked="false"
/>
</template>

<script>
  // Imports
  import Vue from 'vue'
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  export default Vue.extend({
    name: 'PatientCardSibling',
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
        return `Sibling ${this.i+1}`;
      },
      cardType: function(){
        if (this.config.gender=="NA"){
          return "siblingNA";
        }
        else if (this.config.gender=="M"){
          return "siblingBoy";
        }
        else if (this.config.gender=="F"){
          return "siblingGirl";
        }
        return "siblingNA";
      }
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