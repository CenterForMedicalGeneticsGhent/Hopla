<template>
<span>
    {{content}}<br>
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
            return `vcf.file=${this.filePath}`;
        }
    },
    methods:{
    },
})
</script>
