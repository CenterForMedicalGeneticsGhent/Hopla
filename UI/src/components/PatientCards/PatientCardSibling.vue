<template>
<div
id="input_sibling_card"
>
  <PatientCardGeneral
  v-model="config"
  :title="title"
  :cardType="cardType"
  @removeCard="removeCard()"
  :genderLocked="false"
  />
</div>
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
      };
    },
    computed: {
      config:{
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        },
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
      removeCard:function(){
        this.$emit('removeCard');
      }
    },
    mounted: function(){
      //CODE
    },
    watch:{
      //CODE
    },
    })
</script>