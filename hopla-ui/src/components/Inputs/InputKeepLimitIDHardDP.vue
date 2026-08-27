<template>
    <v-checkbox
    density="compact"
    class="InputKeepLimitIDHardDP ma-0 pa-0"
    v-model="keepID"
    :label="label"
    />
</template>


<script>

export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: Boolean,
    },
    data: function(){
        return {
        };
    },
    computed:{
        keepID:{
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            }
        },
        label: function(){
            return `DP Hard Limit ID`;
        }
    },
    methods:{
        //CODE
    },
    mounted: function(){
        //CODE
    }
}
</script>