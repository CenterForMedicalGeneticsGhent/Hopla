<template>
<span>
    Sequencing note:{{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        sequencingNote: String,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.sequencingNote}`;
        }
    },
    methods:{
    },
})
</script>
