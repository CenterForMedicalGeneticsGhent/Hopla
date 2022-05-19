<template>
<v-text-field
id="input_chr_start"
label="Start"
outlined
v-model="chrStart"
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
        chrStart: {
            get: function(){
                return this.value;
            },
            set: function(d){
                if (isNaN(d) || Number(d)<=0 ){
                    this.$emit('input',this.chrStart);
                    this.key++ //Update view and reset to previous valid value
                }
                else {
                    this.$emit('input',Number(d));
                }
            },
        },
    },
    methods:{
        //CODE
    },
}
</script>
