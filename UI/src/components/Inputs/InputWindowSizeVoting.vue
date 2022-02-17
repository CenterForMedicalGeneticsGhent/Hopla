<template>
<v-text-field
label="Window Size Voting"
outlined
v-model="windowSizeVoting"
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
            windowSizeVoting: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',Math.floor(Number(this.windowSizeVoting)));
      },
    },
}
</script>
