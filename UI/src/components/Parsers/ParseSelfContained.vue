<template>
<span>
    self.contained={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        selfContained: Boolean,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            if (this.selfContained===true){
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
