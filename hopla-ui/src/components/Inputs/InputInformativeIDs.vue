<template>
    <v-checkbox
    density="compact"
    class="ma-0 pa-0"
    v-model="keepInformativeIDs"
    label="Informative ID"
    />
</template>


<script>


export default {
    name:"InputInformativeIDs",
    emits: ['update:modelValue'],
    props:{
        modelValue: Boolean,
    },
    data: function() {
        return{};
    },
    computed:{
        keepInformativeIDs: {
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
