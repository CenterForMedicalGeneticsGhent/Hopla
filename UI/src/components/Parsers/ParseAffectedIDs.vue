<template>
<span>
    affected.ids={{content}}<br>
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
            if (paternalGrandfather.diseaseStatus=='affected'){
                return `${paternalGrandfather.sampleID},`;
            }
            return "";
        },
        paternalGrandmother: function(){
            var paternalGrandmother = this.configPedigree.configGrandParentsPaternal.paternalGrandmother;
            if (paternalGrandmother.diseaseStatus=='affected'){
                return `${paternalGrandmother.sampleID},`;
            }
            return "";
        },
        maternalGrandfather: function(){
            var maternalGrandfather = this.configPedigree.configGrandParentsMaternal.maternalGrandfather;
            if (maternalGrandfather.diseaseStatus=='affected'){
                return `${maternalGrandfather.sampleID},`;
            }
            return "";
        },
        maternalGrandmother: function(){
            var maternalGrandmother = this.configPedigree.configGrandParentsMaternal.maternalGrandmother;
            if (maternalGrandmother.diseaseStatus=='affected'){
                return `${maternalGrandmother.sampleID},`;
            }
            return "";
        },
        father: function(){
            var father = this.configPedigree.configParents.father;
            if (father.diseaseStatus=='affected'){
                return `${father.sampleID},`;
            }
            return "";
        },
        mother: function(){
            var mother = this.configPedigree.configParents.mother;
            if (mother.diseaseStatus=='affected'){
                return `${mother.sampleID},`;
            }
            return "";
        },
        siblings: function(){
            var siblingIDs = this.configPedigree.configSiblings;
            var siblingsString = "";
            for (let i=0; i<siblingIDs.length;i++){
                if (siblingIDs[i].diseaseStatus=="affected"){
                    siblingsString+=`${siblingIDs[i].sampleID},`
                }  
            }
            return siblingsString;
        },
        embryos: function(){
            var embryoIDs = this.configPedigree.configEmbryos.embryoList;
            var embryoString="";
            for (let i=0; i<embryoIDs.length; i++){
                if (embryoIDs[i].diseaseStatus=="affected"){
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
