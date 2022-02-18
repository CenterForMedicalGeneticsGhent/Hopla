<template>
<span>
    keep.regions.only={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        keepRegionsOnly: Boolean,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            if (this.keepRegionsOnly===true){
                return 'T';
            }
            else {
                return 'F';
            }
        }
    },
    methods:{
    },
})
</script>
