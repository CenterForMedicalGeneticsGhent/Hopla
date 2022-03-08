<template>
<v-text-field
label="Start"
outlined
v-model="chrStart"
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
            chrStart: this.value,
            chrStartOld: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        handleInput: function(){
                var chrStartNew = Math.ceil(Number(this.chrStart)); //If not number it is transformed to 0
                if (chrStartNew===this.chrStartOld){
                    //Nothing changes, do nothing
                }
                else if (chrStartNew>0){
                    // Valid input
                    this.chrStartOld=chrStartNew;
                    this.$emit('input',chrStartNew);
                } 
                else {
                    //Invalid input, change back to previous value
                    this.chrStart = this.chrStartOld;
                } 
        },
    },
}
</script>
