<template>
    <v-checkbox
    id='input_dp_hard_limit_id'
    dense
    class="InputKeepLimitIDHardDP ma-0 pa-0"
    v-model="keepID"
    :label="label"
    />
</template>


<script>

export default {
    props:{
        value: Boolean,
    },
    data: function(){
        return {
        };
    },
    computed:{
        keepID:{
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
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