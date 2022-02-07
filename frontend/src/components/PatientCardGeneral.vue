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
  </v-card-title>
  <v-card-text>
    {{ config }}
  </v-card-text>
</v-card>
</template>

<script lang="ts">
  import Vue from 'vue'

  export default Vue.extend({
    name: 'PedigreeGroup',
    props:{
      value: Object,
    },
    data: function() {
      return {
        sampleID: null
      }
    },
    computed:{
      config: function(){
        return {
          sampleID: this.sampleID,
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