<template>
<v-container>
    <v-text-field
    label="Disease (breast cancer)"  
    dense
    outlined
    v-model="disease"
    v-on:input="handleInput()"
    type="text"
    />
</v-container>
</template>


<script>
export default {
    props:{
        value: String,
    },
    data: function(){
        return{
            disease: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.disease);
      },
    },
}
</script>
