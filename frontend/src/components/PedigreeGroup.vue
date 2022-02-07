<template>
<v-card
:width="width"
>
  <v-card-title> 
  <v-avatar 
  size="48"
  tile
  >
    <v-img
      :src="imgPath"
    />
  </v-avatar>
  <v-spacer />
  {{ title }}
  <v-spacer />
  </v-card-title>
  <v-card-text>
    <slot></slot>
    {{ config }}
  </v-card-text>
</v-card>
</template>

<script lang="ts">
  declare var require: any

  import Vue from 'vue'

  export default Vue.extend({
    name: 'PedigreeGroup',
    props:{
      value: Object,
      title: String,
      imgType: String,
      width:String,
    },
    data: function() {
      return {
        config: this.value,
      }
    },
    computed:{
      imgPath: function(){
        if (this.imgType=="grandparents1"){
          return require('../assets/grandparents1.png');
        }
        else if (this.imgType=="grandparents2"){
          return require('../assets/grandparents2.png');
        }
        else if (this.imgType=="parents"){
          return require('../assets/parents.png');
        }
        else if (this.imgType=="siblings"){
          return require('../assets/siblings.png');
        }
        else if (this.imgType=="embryos"){
          return require('../assets/embryos.png');
        }
        return false;
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