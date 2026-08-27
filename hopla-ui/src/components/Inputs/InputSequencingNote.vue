<template>
<v-container>
    <v-text-field
    label="Sequencing Note"  
    density="compact"
    variant="outlined"
    v-model="sequencingNote"
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
        sequencingNote:{
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
