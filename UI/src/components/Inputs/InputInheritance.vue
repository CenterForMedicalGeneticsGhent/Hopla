<template>
<v-container>
    <v-autocomplete
    v-model="inheritance"
    :items="options"
    label="Inheritance"
    outlined
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
