<template>
<span>
    nonaffected.ids={{content}}<br>
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
            var paternalGrandfather = this.configPedigree.configGrandParentsPaternal.paternalGrandfather;
            if (paternalGrandfather.diseaseStatus=='nonaffected'){
                return `${paternalGrandfather.sampleID},`;
            }
            return "";
        },
        paternalGrandmother: function(){
            var paternalGrandmother = this.configPedigree.configGrandParentsPaternal.paternalGrandmother;
            if (paternalGrandmother.diseaseStatus=='nonaffected'){
                return `${paternalGrandmother.sampleID},`;
            }
            return "";
        },
        maternalGrandfather: function(){
            var maternalGrandfather = this.configPedigree.configGrandParentsMaternal.maternalGrandfather;
            if (maternalGrandfather.diseaseStatus=='nonaffected'){
                return `${maternalGrandfather.sampleID},`;
            }
            return "";
        },
        maternalGrandmother: function(){
            var maternalGrandmother = this.configPedigree.configGrandParentsMaternal.maternalGrandmother;
            if (maternalGrandmother.diseaseStatus=='nonaffected'){
                return `${maternalGrandmother.sampleID},`;
            }
            return "";
        },
        father: function(){
            var father = this.configPedigree.configParents.father;
            if (father.diseaseStatus=='nonaffected'){
                return `${father.sampleID},`;
            }
            return "";
        },
        mother: function(){
            var mother = this.configPedigree.configParents.mother;
            if (mother.diseaseStatus=='nonaffected'){
                return `${mother.sampleID},`;
            }
            return "";
        },
        siblings: function(){
            var siblingIDs = this.configPedigree.configSiblings;
            var siblingsString = "";
            for (let i=0; i<siblingIDs.length;i++){
                if (siblingIDs[i].diseaseStatus=="nonaffected"){
                    siblingsString+=`${siblingIDs[i].sampleID},`
                }  
            }
            return siblingsString;
        },
        embryos: function(){
            var embryoIDs = this.configPedigree.configEmbryos.embryoList;
            var embryoString="";
            for (let i=0; i<embryoIDs.length; i++){
                if (embryoIDs[i].diseaseStatus=="nonaffected"){
                    embryoString+=`${embryoIDs[i].sampleID},`;
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
