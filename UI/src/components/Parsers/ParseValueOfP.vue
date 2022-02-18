<template>
<span>
    value.of.p={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        valueOfP: Number,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.valueOfP}`;
        }
    },
    methods:{
    },
})
</script>
