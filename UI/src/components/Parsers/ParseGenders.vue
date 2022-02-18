<template>
<span>
    genders={{content}}<br>
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
            if (paternalGrandfather.sampleID!='U3'){
                return `${paternalGrandfather.gender},`;
            }
            return "";
        },
        paternalGrandmother: function(){
            var paternalGrandmother = this.configPedigree.configGrandParentsPaternal.paternalGrandmother;
            if (paternalGrandmother.sampleID!='U4'){
                return `${paternalGrandmother.gender},`;
            }
            return "";
        },
        maternalGrandfather: function(){
            var maternalGrandfather = this.configPedigree.configGrandParentsMaternal.maternalGrandfather;
            if (maternalGrandfather.sampleID!='U5'){
                return `${maternalGrandfather.gender},`;
            }
            return "";
        },
        maternalGrandmother: function(){
            var maternalGrandmother = this.configPedigree.configGrandParentsMaternal.maternalGrandmother;
            if (maternalGrandmother.sampleID!='U6'){
                return `${maternalGrandmother.gender},`;
            }
            return "";
        },
        father: function(){
            var paternalGrandfather = this.configPedigree.configGrandParentsPaternal.paternalGrandfather;
            var paternalGrandmother = this.configPedigree.configGrandParentsPaternal.paternalGrandmother;
            var father = this.configPedigree.configParents.father;
            if (paternalGrandmother.sampleID!="U4" || paternalGrandfather.sampleID!="U3" || father.sampleID!='U1'){
                return `${father.gender},`;
            }
            return "";
        },
        mother: function(){
            var maternalGrandfather = this.configPedigree.configGrandParentsMaternal.maternalGrandfather;
            var maternalGrandmother = this.configPedigree.configGrandParentsMaternal.maternalGrandmother;
            var mother = this.configPedigree.configParents.mother;
            if (maternalGrandmother.sampleID!="U6" || maternalGrandfather.sampleID!="U5" || mother.sampleID!='U2'){
                return `${mother.gender},`;
            }
            return "";
        },
        siblings: function(){
            var siblings = this.configPedigree.configSiblings;
            var siblingsString = "";
            for (let i=0; i<siblings.length;i++){
                siblingsString+=`${siblings[i].gender},`
            }
            return siblingsString;
        },
        embryos: function(){
            var embryos = this.configPedigree.configEmbryos.embryoList;
            var embryoString="";
            for (let i=0; i<embryos.length; i++){
                embryoString+=`${embryos[i].gender},`;
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
