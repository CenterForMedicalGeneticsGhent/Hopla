<template>
<v-text-field
label="Window Size Voting"
variant="outlined"
v-model="windowSizeVoting"
type="number"
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
        return {
            key:0,
        }
    },
    computed:{
        windowSizeVoting:{
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                if (isNaN(d) || Number(d)<=0 ){
                    this.$emit('update:modelValue',this.windowSizeVoting);
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
