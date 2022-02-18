<template>
<span>
    dp.hard.limit.ids={{content}}<br>
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
                if (paternalGrandfather.keepLimitIDHardDP){
                    return `${paternalGrandfather.sampleID},`;
                }
                else {
                    return ``;
                }
            }
            return "";
        },
        paternalGrandmother: function(){
            var paternalGrandmother = this.configPedigree.configGrandParentsPaternal.paternalGrandmother;
            if (paternalGrandmother.sampleID!='U4'){
                if (paternalGrandmother.keepLimitIDHardDP){
                    return `${paternalGrandmother.sampleID},`;
                }
                else {
                    return ``;
                }
            }
            return "";
        },
        maternalGrandfather: function(){
            var maternalGrandfather = this.configPedigree.configGrandParentsMaternal.maternalGrandfather;
            if (maternalGrandfather.sampleID!='U5'){
                if (maternalGrandfather.keepLimitIDHardDP){
                    return `${maternalGrandfather.sampleID},`;
                }
                else {
                    return ``;
                }
            }
            return "";
        },
        maternalGrandmother: function(){
            var maternalGrandmother = this.configPedigree.configGrandParentsMaternal.maternalGrandmother;
            if (maternalGrandmother.sampleID!='U6'){
                if (maternalGrandmother.keepLimitIDHardDP){
                    return `${maternalGrandmother.sampleID},`;
                }
                else {
                    return ``;
                }
            }
            return "";
        },
        father: function(){
            var paternalGrandfather = this.configPedigree.configGrandParentsPaternal.paternalGrandfather;
            var paternalGrandmother = this.configPedigree.configGrandParentsPaternal.paternalGrandmother;
            var father = this.configPedigree.configParents.father;
            if (paternalGrandmother.sampleID!="U4" || paternalGrandfather.sampleID!="U3" || father.sampleID!='U1'){
                if (father.keepLimitIDHardDP===true){
                    return `${father.sampleID},`;
                }
                else {
                    return ``;
                }
            }
            return "";
        },
        mother: function(){
            var maternalGrandfather = this.configPedigree.configGrandParentsMaternal.maternalGrandfather;
            var maternalGrandmother = this.configPedigree.configGrandParentsMaternal.maternalGrandmother;
            var mother = this.configPedigree.configParents.mother;
            if (maternalGrandmother.sampleID!="U6" || maternalGrandfather.sampleID!="U5" || mother.sampleID!='U2'){
                if (mother.keepLimitIDHardDP===true){
                    return `${mother.sampleID},`;
                }
                else {
                    return ``;
                }
            }
            return "";
        },
        siblings: function(){
            var siblings = this.configPedigree.configSiblings;
            var siblingsString = "";
            for (let i=0; i<siblings.length;i++){
                if (siblings[i].keepLimitIDHardDP===true){
                    siblingsString+=`${siblings[i].sampleID},`;
                }
            }
            return siblingsString;
        },
        embryos: function(){
            // Do nothing for embryos
            //var embryos = this.configPedigree.configEmbryos.embryoList;
            var embryoString="";
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
