<template>
<v-container>
    <v-text-field
    class="ma-0 pa-0"
    label="Cytoband file absolute path"
    dense
    outlined
    v-model="fileCytoband"
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
            fileCytoband: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.fileCytoband);
      },
    },
}
</script>
