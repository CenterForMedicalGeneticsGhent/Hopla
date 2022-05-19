<template>
    <v-autocomplete
    id="input_inheritance"
    v-model="inheritance"
    :items="options"
    label="Inheritance"
    outlined
    />
</template>


<script>
export default {
    name: 'InputInheritance',
    props:{
        value: String,
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
