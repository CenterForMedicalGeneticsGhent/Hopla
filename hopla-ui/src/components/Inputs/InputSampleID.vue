<template>
    <v-text-field
    class="ma-0 pa-0"
    label="Sample ID"
    density="compact"
    variant="outlined"
    v-model="sampleID"
    type="text"
    />
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
        sampleID: {
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
    },
    methods:{
    },
}
</script>
