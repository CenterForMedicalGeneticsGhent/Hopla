<template>
<span>
    Disease:{{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        disease: String,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.disease}`;
        }
    },
    methods:{
    },
})
</script>
