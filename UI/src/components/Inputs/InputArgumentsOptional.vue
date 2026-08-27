<template>
<v-container>
<v-card>
    <v-card-title>
        Optional Arguments
    </v-card-title>
    <v-card-text>
        <InputFileCytoband 
        v-model="fileCytoband"
        />
    </v-card-text>
</v-card>
</v-container>
</template>


<script>
import InputFileCytoband from "./InputFileCytoband.vue";

export default {
    name: 'InputArgumentsOptional',
    emits: ['update:modelValue'],
    props:{
      modelValue: String,
    },
    components:{
      InputFileCytoband,
    },
    data: function(){
      return{
      }
    },
    computed:{
      fileCytoband: {
        get: function(){
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
    mounted:function(){
      //CODE
    },
    watch:{
      //CODE
    },
}
</script>