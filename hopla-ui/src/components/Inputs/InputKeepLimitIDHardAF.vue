<template>
    <v-checkbox
    density="compact"
    class="ma-0 pa-0"
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
            get:function(){
                return this.modelValue;
            },
            set:function(d){
                this.$emit('update:modelValue',d);
            },
        },
        label: function(){
            return `AF Hard Limit ID`;
        }
    },
    methods:{
    },
    mounted: function(){
        //CODE
    }
}
</script>
