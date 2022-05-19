<template>
<div
id="input_embryo_card"
>
<PatientCardGeneral
v-model="config"
:title="title"
cardType="embryo"
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
      };
    },
    computed: {
      config:{
        get:function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        },
      },
      title: function(){
        return `Embryo ${this.i+1}`;
      },
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
    },
    })
</script>