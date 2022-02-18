<template>
<span>
    regions={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        regions:Array,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            var contentString="";
            for (let i=0; i<this.regions.length;i++){
                let regionI = this.regions[i];
                contentString+=`${regionI.chr}:${regionI.chrStart}-${regionI.chrEnd},`
            }
            return contentString.slice(0,-1);
        }
    },
    methods:{
    },
})
</script>
