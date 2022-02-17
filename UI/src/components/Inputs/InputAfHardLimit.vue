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
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',Number(this.afHardLimit));
      },
    },
}
</script>
