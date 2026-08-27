<template>
<v-text-field
label="Value of P"
:disabled="disabled"
variant="outlined"
v-model="valueOfP"
:key="key"
/>
</template>


<script>
export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: Number,
        disabled: Boolean,
    },
    data: function(){
        return{
            key:0,
        }
    },
    computed:{
        valueOfP:{
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                if (isNaN(+d) || +d<0 || +d>1){
                    this.$emit('update:modelValue',this.valueOfP);
                    this.key++ //Update view and reset to previous valid value
                }
                else {
                    this.$emit('update:modelValue',Number(d));
                }
            }
        },
    },
    methods:{
        //CODE
    },
}
</script>
