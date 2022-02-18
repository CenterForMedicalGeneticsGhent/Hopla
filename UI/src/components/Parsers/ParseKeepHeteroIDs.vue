<template>
<span>
    keep.hetero.ids={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        configPedigree: Object,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        paternalGrandfather: function(){
            return "";
        },
        paternalGrandmother: function(){
            return "";
        },
        maternalGrandfather: function(){
            return "";
        },
        maternalGrandmother: function(){
            return "";
        },
        father: function(){
            return "";
        },
        mother: function(){
            return "";
        },
        siblings: function(){
            var siblingsString = "";
            return siblingsString;
        },
        embryos: function(){
            var embryos = this.configPedigree.configEmbryos.embryoList;
            var keepHeteroIDs = this.configPedigree.configEmbryos.keepHeteroIDs;
            var embryoString="";
            if (keepHeteroIDs===true){
                for (let i=0;i<embryos.length;i++){
                    embryoString+=`${embryos[i].sampleID},`;
                }
            }
            return embryoString;
        },
        content: function(){
            var content=`${this.paternalGrandfather}${this.paternalGrandmother}${this.maternalGrandfather}${this.maternalGrandmother}${this.father}${this.mother}${this.siblings}${this.embryos}`;
            if (content){
                return content.slice(0,-1);
            }
            else {
                return "";
            }
        }
    },
    methods:{
    },
})
</script>
