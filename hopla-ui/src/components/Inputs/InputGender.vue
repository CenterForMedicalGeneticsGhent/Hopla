<template>
    <v-avatar 
    density="compact"
    size="30"
    :color="color"
    @mouseover="hover = true"
    @mouseleave="hover = false"
    @click="goToNextOption()"
    >
        <v-img
        :src="imgSrc"
        />
    </v-avatar>
</template>


<script>
import maleImg from "../../assets/male.png";
import femaleImg from "../../assets/female.png";
import genderUnknownImg from "../../assets/genderUnknown.png";

const genderOptions = [
    {gender:"M", color:"rgba(0,120,255,0.2)"},
    {gender:"F", color:"rgba(255,0,0,0.2)"},
    {gender:"NA", color:"rgba(0,0,0,0.2)"},
];

export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: String,
        genderLocked: Boolean,
    },
    data: function(){
        return{
            hover: false,
        }
    },
    computed:{
        genderOptionChosen: {
            get: function(){
                return this.getGenderIndex(this.modelValue);
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
        color: function(){
            var color;
            if (this.hover){
                color = genderOptions[this.genderOptionChosen]["color"];
            }
            return color;
        },
        imgSrc: function(){
            var gender=this.gender;
            if (gender==="M"){
                return maleImg;
            }
            else if (gender==="F"){
                return femaleImg;
            }
            else if (gender==="NA"){
                return genderUnknownImg;
            }
            return false;
        },
        gender: function(){
            return genderOptions[this.genderOptionChosen]["gender"];
        }
    },
    methods:{
      getGenderIndex(g){
            for (let i=0; i<genderOptions.length;i++){
                if (genderOptions[i]["gender"]==g){
                    return i;
                }
            }
            return 0;
      },
      goToNextOption: function(){
          if (!this.genderLocked){
            var genderIndex = (this.genderOptionChosen+1) % genderOptions.length;
            this.genderOptionChosen=genderOptions[genderIndex]["gender"];
          }    
      }
    },
    mounted: function(){
        // CODE
    }
}
</script>
