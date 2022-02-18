<template>
<span>
    cytoband.file={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        filePath: String,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.filePath}`;
        }
    },
    methods:{
    },
})
</script>
