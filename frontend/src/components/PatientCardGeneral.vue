<template>
<v-card
width="250px"
>
  <v-card-title> 
  <v-avatar 
  size="48"
  tile
  >
    <v-img
      src="../assets/embryos.png"
    />
  </v-avatar>
  <v-spacer />
  Embryo 1
  <v-spacer />
   <InputGender v-model="gender" />
  </v-card-title>
  <v-card-text>
    <InputSampleID v-model="sampleID" />
    {{ config }}
  </v-card-text>
</v-card>
</template>

<script lang="ts">
  import Vue from 'vue'
  import InputSampleID from "./InputSampleID.vue";
  import InputGender from "./InputGender.vue";

  export default Vue.extend({
    name: 'PedigreeGroup',
    components: {
      InputSampleID,
      InputGender,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        sampleID: null,
        gender: "NA",
      }
    },
    computed:{
      config: function(){
        return {
          sampleID: this.sampleID,
          gender: this.gender,
        }
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