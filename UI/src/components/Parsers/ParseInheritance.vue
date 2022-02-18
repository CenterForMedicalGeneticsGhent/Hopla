<template>
<span>
    Inheritance:{{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        inheritance: String,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.inheritance}`;
        }
    },
    methods:{
    },
})
</script>
