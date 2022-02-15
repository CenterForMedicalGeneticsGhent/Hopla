<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="keepLimitID"
    :label="label"
    @click="handleInput()"
    />
</template>


<script>

export default {
    props:{
        value: Boolean,
        limitType: String,
    },
    data: function(){
        let d  = {
            keepLimitID: this.value,
        };
        return d;
    },
    computed:{
        label: function(){
            return `Keep ${this.limitType} Limit ID`;
        }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.keepLimitID);
      },
    },
    mounted: function(){
        //CODE
    }
}
</script>
