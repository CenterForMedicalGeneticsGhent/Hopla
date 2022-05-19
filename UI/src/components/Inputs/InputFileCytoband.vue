<template>
<v-container>
    <v-text-field
    id="input_cytoband_file"
    class="ma-0 pa-0"
    label="Cytoband file absolute path"
    dense
    outlined
    v-model="fileCytoband"
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
        fileCytoband: {
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            }
        },
    },
    methods:{
        //CODE
    },
}
</script>
