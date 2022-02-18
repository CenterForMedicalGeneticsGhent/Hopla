<template>
<span>
    window.size.voting={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        windowSizeVoting: String,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.windowSizeVoting}`;
        }
    },
    methods:{
    },
})
</script>
