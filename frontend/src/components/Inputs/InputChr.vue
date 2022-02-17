<template>
<v-autocomplete
v-model="chr"
:items="chrOptions"
label="Chromosome"
outlined
@change="handleInput()"
/>
</template>


<script>
export default {
    props:{
        value: String,
    },
    data: function(){
        return{
            chr: this.value,
            chrOptions: [
                'chr1','chr2','chr3','chr4','chr5','chr6','chr7','chr8','chr9','chr10',
                'chr11','chr12','chr13','chr14','chr15','chr16','chr17','chr18','chr19','chr20',
                'chr21','chr22','chrX','chrY',
            ],
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.chr);
      },
    },
}
</script>
