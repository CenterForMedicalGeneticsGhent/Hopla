<template>
<v-autocomplete
v-model="regionsFlankingSize"
:items="options"
label="Regions Flanking Size"
outlined
/>
</template>


<script>
export default {
    props:{
        value: Number,
    },
    data: function(){
        return {
            options: [
                1000000,
                2000000,
            ],
        }
    },
    computed:{
        regionsFlankingSize: {
            get:function(){
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
