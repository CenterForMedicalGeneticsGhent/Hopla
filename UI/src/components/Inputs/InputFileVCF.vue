<template>
<v-container>
    <v-text-field
    class="ma-0 pa-0"
    label="VCF file absolute path"
    density="compact"
    variant="outlined"
    v-model="fileVCF"
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
        fileVCF:{
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
    },
    methods:{
        //CODE
    },
}
</script>
