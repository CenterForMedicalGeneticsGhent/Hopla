<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="keepBafIDs"
    label="BAF ID"
    />
</template>


<script>
import Vue from 'vue';


export default Vue.extend({
    name:"InputBafIDs",
    props:{
        value: Boolean,
    },
    data: function() {
        return{};
    },
    computed:{
        keepBafIDs: {
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            },
        },
    },
    methods:{
    },
    mounted: function(){
        //CODE
    }
})
</script>
