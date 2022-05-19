<template>
    <v-checkbox
    id='input_informative_id'
    dense
    class="ma-0 pa-0"
    v-model="keepInformativeIDs"
    label="Informative ID"
    />
</template>


<script>
import Vue from 'vue';


export default Vue.extend({
    name:"InputInformativeIDs",
    props:{
        value: Boolean,
    },
    data: function() {
        return{};
    },
    computed:{
        keepInformativeIDs: {
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
