<template>
<v-container>
    <v-text-field
    label="Disease (e.g. breast cancer)"  
    density="compact"
    variant="outlined"
    v-model="disease"
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
        disease:{
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
