<template>
    <v-avatar
    id="input_gender" 
    dense
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
const genderOptions = [
    {gender:"M", color:"rgba(0,120,255,0.2)"},
    {gender:"F", color:"rgba(255,0,0,0.2)"},
    {gender:"NA", color:"rgba(0,0,0,0.2)"},
];

export default {
    name: "InputGender",
    props:{
        value: String,
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
                return this.getGenderIndex(this.value);
            },
            set: function(d){
                this.$emit('input',d);
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
                return require("../../assets/male.png");
            }
            else if (gender==="F"){
                return require("../../assets/female.png");
            }
            else if (gender==="NA"){
                return require("../../assets/genderUnknown.png");
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
