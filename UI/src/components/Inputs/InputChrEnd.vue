<template>
<v-text-field
label="End"
outlined
v-model="chrEnd"
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
            chrEnd: this.value,
            chrEndOld: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        handleInput: function(){
            var chrEndNew = Math.ceil(Number(this.chrEnd)); //If not number it is transformed to 0
            if (chrEndNew===this.chrEndOld){
                //Nothing changes, do nothing
            }
            else if (chrEndNew>0){
                // Valid input
                this.chrEndOld=chrEndNew;
                this.$emit('input',chrEndNew);
            } 
            else {
                //Invalid input, change back to previous value
                this.chrEnd = this.chrEndOld;
            } 
        },
    },
}
</script>
