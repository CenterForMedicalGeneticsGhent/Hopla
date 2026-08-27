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
  import PatientCardGeneral from "./PatientCardGeneral.vue";

  export default {
    name: 'PatientCardEmbryo',
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
        get:function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
    }
</script>