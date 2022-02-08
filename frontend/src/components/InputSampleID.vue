<template>
    <v-text-field
    class="ma-0 pa-0"
    label="Sample ID"
    outlined
    v-model="sampleID"
    v-on:input="handleInput()"
    type="text"
    />
</template>


<script>
export default {
    props:{
        value: String,
    },
    data: function(){
        return{
            sampleID: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.sampleID);
      },
    },
}
</script>
