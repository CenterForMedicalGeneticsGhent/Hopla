<template>
<v-autocomplete
v-model="chr"
:items="chrOptions"
label="Chromosome"
variant="outlined"
/>
</template>


<script>
export default {
    emits: ['update:modelValue'],
    props:{
        modelValue: String,
    },
    data: function(){
        return{
            chrOptions: [
                'chr1','chr2','chr3','chr4','chr5','chr6','chr7','chr8','chr9','chr10',
                'chr11','chr12','chr13','chr14','chr15','chr16','chr17','chr18','chr19','chr20',
                'chr21','chr22','chrX','chrY',
            ],
        }
    },
    computed:{
        chr: {
            get:function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
    },
    methods:{
      //CODE
    },
}
</script>
