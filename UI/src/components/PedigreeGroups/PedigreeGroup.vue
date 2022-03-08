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
        :title="imgLicense"
      />
    </v-avatar>
    <v-spacer />
    {{ title }}
    <v-spacer />
  </v-card-title>
  <v-card-text>
    <slot></slot>
  </v-card-text>
</v-card>
</template>

<script>
  import Vue from 'vue'

  export default Vue.extend({
    name: 'PedigreeGroup',
    props:{
      value: null,
      title: String,
      imgType: String,
      width:String,
      imgLicense: String,
    },
    data: function() {
      return {
        config: this.value,
      }
    },
    computed:{
      imgPath: function(){
        if (this.imgType=="grandparents1"){
          return require('../../assets/grandparents1.png');
        }
        else if (this.imgType=="grandparents2"){
          return require('../../assets/grandparents2.png');
        }
        else if (this.imgType=="parents"){
          return require('../../assets/parents.png');
        }
        else if (this.imgType=="siblings"){
          return require('../../assets/siblings.png');
        }
        else if (this.imgType=="embryos"){
          return require('../../assets/embryos.png');
        }
        return false;
      },
      configWatcher: {
        get: function(){
          return `
            ${JSON.stringify(this.config)}
          `;
        }
      },
      btnText: function(){
        return `Add ${this.title.slice(0,-1)}`;
      }
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