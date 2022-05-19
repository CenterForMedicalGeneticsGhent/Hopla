<template>
    <v-checkbox
    id="input_hetero_id"
    dense
    class="ma-0 pa-0"
    v-model="keepHeteroIDs"
    label="Keep Heterogenous IDs"
    />
</template>


<script>

export default {
    props:{
        value: Boolean,
    },
    data: function(){
        return{
        };
    },
    computed:{
        keepHeteroIDs:{
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
    mounted: function(){
        //CODE
    }
}
</script>
