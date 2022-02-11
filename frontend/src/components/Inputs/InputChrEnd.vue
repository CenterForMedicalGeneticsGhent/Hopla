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
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',Math.ceil(Number(this.chrEnd)));
      },
    },
}
</script>
