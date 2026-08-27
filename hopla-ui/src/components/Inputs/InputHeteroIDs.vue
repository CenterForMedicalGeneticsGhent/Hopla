<template>
    <v-checkbox
    density="compact"
    class="ma-0 pa-0"
    v-model="keepHeteroIDs"
    label="Keep Heterogenous IDs"
    />
</template>


<script>

export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: Boolean,
    },
    data: function(){
        return{
        };
    },
    computed:{
        keepHeteroIDs:{
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
    mounted: function(){
        //CODE
    }
}
</script>
