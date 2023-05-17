<template>
<v-text-field
label="Regions Flankinh Size"
outlined
v-model="regionsFlankingSize"
type="number"
:key="key"
/>
</template>


<script>
export default {
    props:{
        value: Number,
    },
    data: function(){
        return {
            key:0,
        }
    },
    computed:{
        regionsFlankingSize:{
            get: function(){
                return this.value;
            },
            set: function(d){
                if (isNaN(d) || Number(d)<=0 ){
                    this.$emit('input',this.regionsFlankingSize);
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
