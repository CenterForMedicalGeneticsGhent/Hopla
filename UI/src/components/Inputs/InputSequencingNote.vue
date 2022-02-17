<template>
<v-container>
    <v-text-field
    label="Sequencing Note"  
    dense
    outlined
    v-model="sequencingNote"
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
            sequencingNote: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.sequencingNote);
      },
    },
}
</script>
