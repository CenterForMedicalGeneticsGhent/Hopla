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
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',Number(this.valueOfP));
      },
    },
}
</script>
