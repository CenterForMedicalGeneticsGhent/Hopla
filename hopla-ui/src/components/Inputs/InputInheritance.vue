<template>
<v-container>
    <v-autocomplete
    v-model="inheritance"
    :items="options"
    label="Inheritance"
    variant="outlined"
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
            options: [
                'AD',
                'AR',
                'XLD',
                'XLR',
            ],
        }
    },
    computed:{
        inheritance:{
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
