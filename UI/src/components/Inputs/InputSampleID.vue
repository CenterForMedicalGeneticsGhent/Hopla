<template>
    <v-text-field
    id="input_sample_id"
    class="ma-0 pa-0"
    label="Sample ID"
    dense
    outlined
    v-model="sampleID"
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
        }
    },
    computed:{
        sampleID: {
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            },
        },
    },
    methods:{
    },
}
</script>
