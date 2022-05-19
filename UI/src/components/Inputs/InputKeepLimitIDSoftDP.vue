<template>
    <v-checkbox
    id="input_dp_soft_limit_id"
    dense
    class="ma-0 pa-0"
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
        keepID: {
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            }
        },
        label: function(){
            return `DP Soft Limit ID`;
        }
    },
    methods:{
    },
    mounted: function(){
        //CODE
    }
}
</script>
