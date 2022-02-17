<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="limitPmToP"
    label="Limit PM to P"
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
            limitPmToP: this.value,
        };
        return d;
    },
    computed:{
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.limitPmToP);
      },
    },
    mounted: function(){
        //CODE
    }
}
</script>
