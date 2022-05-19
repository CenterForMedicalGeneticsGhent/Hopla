<template>
<v-text-field
id="input_value_of_p"
label="Value of P"
:disabled="disabled"
outlined
v-model="valueOfP"
:key="key"
/>
</template>


<script>
export default {
    props:{
        value: Number,
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
                return this.value;
            },
            set: function(d){
                if (isNaN(+d) || +d<0 || +d>1){
                    this.$emit('input',this.valueOfP);
                    this.key++ //Update view and reset to previous valid value
                }
                else {
                    this.$emit('input',Number(d));
                }
            }
        },
    },
    methods:{
        //CODE
    },
}
</script>
