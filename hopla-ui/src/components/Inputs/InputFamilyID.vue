<template>
<v-container>
    <v-text-field
    label="Family ID"  
    density="compact"
    variant="outlined"
    v-model="famID"
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
        famID: {
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            }
        }
    },
    methods:{
    },
}
</script>
