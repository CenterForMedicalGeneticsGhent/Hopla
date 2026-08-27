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
  import grandparents1Img from '../../assets/grandparents1.png';
  import grandparents2Img from '../../assets/grandparents2.png';
  import parentsImg from '../../assets/parents.png';
  import siblingsImg from '../../assets/siblings.png';
  import embryosImg from '../../assets/embryos.png';

  export default {
    name: 'PedigreeGroup',
    emits: ['update:modelValue'],
    props:{
      modelValue: null,
      title: String,
      imgType: String,
      width:String,
      imgLicense: String,
    },
    data: function() {
      return {
      }
    },
    computed:{
      config:{
        get: function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
        },
      },
      imgPath: function(){
        if (this.imgType=="grandparents1"){
          return grandparents1Img;
        }
        else if (this.imgType=="grandparents2"){
          return grandparents2Img;
        }
        else if (this.imgType=="parents"){
          return parentsImg;
        }
        else if (this.imgType=="siblings"){
          return siblingsImg;
        }
        else if (this.imgType=="embryos"){
          return embryosImg;
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
    },
    mounted: function(){
      //CODE
    },
    watch:{
      //CODE
    },
    }
</script>
