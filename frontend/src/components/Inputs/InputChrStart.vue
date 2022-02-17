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
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',Math.floor(Number(this.chrStart)));
      },
    },
}
</script>
