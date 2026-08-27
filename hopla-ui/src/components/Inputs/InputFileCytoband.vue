<template>
<v-container>
    <v-text-field
    class="ma-0 pa-0"
    label="Cytoband file absolute path"
    density="compact"
    variant="outlined"
    v-model="fileCytoband"
    type="text"
    />
</v-container>
</template>


<script>
export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: String,
    },
    data: function(){
        return{
        }
    },
    computed:{
        fileCytoband: {
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            }
        },
    },
    methods:{
        //CODE
    },
}
</script>
