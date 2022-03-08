<template>
<v-text-field
label="af.hard.limit"
outlined
v-model="afHardLimit"
type="number"
@change="handleInput()"
/>
</template>


<script>
export default {
    props:{
        value: Number,
    },
    data: function(){
        return{
            afHardLimit: this.value,
            afHardLimitOld: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        handleInput: function(){
            var afHardLimitNew = Number(this.afHardLimit); //If not number it is transformed to 0
            if (afHardLimitNew===this.afHardLimitOld){
                //Nothing changes, do nothing
            }
            else if (afHardLimitNew>0 && afHardLimitNew<=1){
                // Valid input
                this.afHardLimitOld=afHardLimitNew;
                this.$emit('input',afHardLimitNew);
            } 
            else {
                //Invalid input, change back to previous value
                this.afHardLimit = this.afHardLimitOld;
            } 
        },
    },
}
</script>
