<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="limitPmToP"
    label="Limit PM to P"
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
        limitPmToP:{
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            },
        },
    },
    methods:{
        //CODE
    },
    mounted: function(){
        //CODE
    }
}
</script>
