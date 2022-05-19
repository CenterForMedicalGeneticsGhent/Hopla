<template>
<v-text-field
id="input_af_hard_limit"
label="af.hard.limit"
outlined
v-model="afHardLimit"
:key="key"
/>
</template>


<script>
export default {
    props:{
        value: Number,
    },
    data: function(){
        return{
            key:0,
        }
    },
    computed:{
        afHardLimit: {
            get: function(){
                return this.value;
            },
            set: function(d){
                if (isNaN(+d) || +d<0 || +d>1){
                    this.$emit('input',this.afHardLimit);
                    this.key++ //Update view and reset to previous valid value
                }
                else {
                    var afHardLimitNew = Number(d);    
                    this.$emit('input',afHardLimitNew);
                }
            },
        },
    },
    methods:{
        //CODE
    },
}
</script>
