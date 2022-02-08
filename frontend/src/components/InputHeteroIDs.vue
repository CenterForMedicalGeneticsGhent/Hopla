<template>
    <v-checkbox
    v-model="keepHeteroIDs"
    label="Keep Heterogenous IDs"
    @click="handleInput()"
    />
</template>


<script>

export default {
    props:{
        value: Boolean,
    },
    data: function(){
        let d  = {
            keepHeteroIDs: this.value,
        };
        return d;
    },
    computed:{
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.keepHeteroIDs);
      },
    },
    mounted: function(){
        //CODE
    }
}
</script>
