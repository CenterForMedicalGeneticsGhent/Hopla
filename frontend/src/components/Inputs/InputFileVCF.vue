<template>
    <v-text-field
    class="ma-0 pa-0"
    label="VCF file absolute path"
    dense
    outlined
    v-model="fileVCF"
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
            fileVCF: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.fileVCF);
      },
    },
}
</script>
