<template>
    <v-checkbox
    dense
    class="ma-0 pa-0"
    v-model="keepInformativeIDs"
    label="Keep Informative IDs"
    @click="handleInput()"
    />
</template>


<script lang>

export default {
    props:{
        value: Boolean,
    },
    data: function(){
        let d  = {
            keepInformativeIDs: this.value,
        };
        return d;
    },
    computed:{
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.keepInformativeIDs);
      },
    },
    mounted: function(){
        //CODE
    }
}
</script>
