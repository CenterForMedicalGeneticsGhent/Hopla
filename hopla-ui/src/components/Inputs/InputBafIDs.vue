<template>
    <v-checkbox
    density="compact"
    class="ma-0 pa-0"
    v-model="keepBafIDs"
    label="BAF ID"
    />
</template>


<script>


export default {
    name:"InputBafIDs",
    emits: ['update:modelValue'],
    props:{
        modelValue: Boolean,
    },
    data: function() {
        return{};
    },
    computed:{
        keepBafIDs: {
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
    },
    methods:{
    },
    mounted: function(){
        //CODE
    }
}
</script>
