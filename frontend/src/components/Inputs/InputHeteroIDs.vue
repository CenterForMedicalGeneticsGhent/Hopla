<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="keepHeteroIDs"
    label="Heterogenous ID"
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
