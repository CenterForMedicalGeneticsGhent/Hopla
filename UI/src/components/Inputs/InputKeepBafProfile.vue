<template>
    <v-checkbox
    id="input_baf_profile"
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
            return `Keep BAF Profile`;
        }
    },
    methods:{
    },
    mounted: function(){
        //CODE
    }
}
</script>
