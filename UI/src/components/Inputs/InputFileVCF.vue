<template>
<v-container>
    <v-text-field
    id="input_vcf_file"
    class="ma-0 pa-0"
    label="VCF file absolute path"
    dense
    outlined
    v-model="fileVCF"
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
        }
    },
    computed:{
        fileVCF:{
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            },
        },
    },
    methods:{
        //CODE
    },
}
</script>
