<template>
    <v-avatar 
    size="32"
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
    props:{
        value: String,
    },
    data: function(){
        return{
            hover: false,
            genderOptionChosen: this.getInitialGender(),
        }
    },
    computed:{
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
                return require("../assets/male.png");
            }
            else if (gender==="F"){
                return require("../assets/female.png");
            }
            else if (gender==="NA"){
                return require("../assets/genderUnknown.png");
            }
            return false;
        },
        gender: function(){
            return genderOptions[this.genderOptionChosen]["gender"];
        }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.gender);
      },
      getInitialGender(){
            for (let i=0; i<genderOptions.length;i++){
                if (genderOptions[i]["gender"]==this.value){
                    return i;
                }
            }
            return 0;
      },
      goToNextOption: function(){
          this.genderOptionChosen = (this.genderOptionChosen+1) % genderOptions.length;
          this.handleInput();
      }
    },
    mounted: function(){
        // CODE
    }
}
</script>
