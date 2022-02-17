<template>
<v-container>
    <v-text-field
    label="Family ID"  
    dense
    outlined
    v-model="famID"
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
            famID: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.famID);
      },
    },
}
</script>
