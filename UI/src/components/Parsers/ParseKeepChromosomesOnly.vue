<template>
<span>
    keep.chromosomes.only={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        keepChromosomesOnly: Boolean,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            if (this.keepChromosomesOnly===true){
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
