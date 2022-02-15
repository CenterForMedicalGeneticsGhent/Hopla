<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="keepID"
    :label="label"
    @click="handleInput()"
    />
</template>


<script>

export default {
    props:{
        value: Boolean,
    },
    data: function(){
        return {
            keepID: this.value,
        };
    },
    computed:{
        label: function(){
            return `Keep DP Hard Limit IDs`;
        }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.keepID);
      },
    },
    mounted: function(){
        //CODE
    }
}
</script>
