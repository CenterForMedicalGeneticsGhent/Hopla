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
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  export default {
    name: 'PatientCardSibling',
    emits: ['update:modelValue', 'removeCard'],
    components: {
      PatientCardGeneral,
    },
    props:{
      modelValue: Object,
      i: Number,
    },
    data: function() {
      return {
      };
    },
    computed: {
      config:{
        get: function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
    }
</script>