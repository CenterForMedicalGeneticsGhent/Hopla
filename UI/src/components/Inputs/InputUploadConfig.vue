<template>
<v-container>
    <v-file-input
    placeholder="Upload config"
    dense
    prepend-inner-icon="mdi-upload"
    prepend-icon=""
    rounded
    filled
    />
</v-container>
</template>


<script>
export default {
    props:{
        value: Object,
    },
    data: function(){
        return {
            config: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        //CODE
    },
}
</script>
