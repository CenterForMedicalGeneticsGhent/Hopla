<template>
<v-text-field
label="Value of P"
:disabled="disabled"
outlined
v-model="valueOfP"
type="number"
@change="handleInput()"
/>
</template>


<script>
export default {
    props:{
        value: Number,
        disabled: Boolean,
    },
    data: function(){
        return{
            valueOfP: this.value,
            valueOfPOld: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        handleInput: function(){
            var valueOfPNew = Number(this.valueOfP); //If not number it is transformed to 0
            if (valueOfPNew===this.valueOfPOld){
                //Nothing changes, do nothing
            }
            else if (valueOfPNew>0 && valueOfPNew<=1){
                // Valid input
                this.valueOfPOld=valueOfPNew;
                this.$emit('input',valueOfPNew);
            } 
            else {
                //Invalid input, change back to previous value
                this.valueOfP = this.valueOfPOld;
            } 
        },
    },
}
</script>
