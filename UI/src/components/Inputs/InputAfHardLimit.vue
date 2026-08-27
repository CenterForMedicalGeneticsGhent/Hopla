<template>
<v-text-field
label="af.hard.limit"
variant="outlined"
v-model="afHardLimit"
:key="key"
/>
</template>


<script>
export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: Number,
    },
    data: function(){
        return{
            key:0,
        }
    },
    computed:{
        afHardLimit: {
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                if (isNaN(+d) || +d<0 || +d>1){
                    this.$emit('update:modelValue',this.afHardLimit);
                    this.key++ //Update view and reset to previous valid value
                }
                else {
                    var afHardLimitNew = Number(d);    
                    this.$emit('update:modelValue',afHardLimitNew);
                }
            },
        },
    },
    methods:{
        //CODE
    },
}
</script>
