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
import Vue from 'vue';
import InputFileCytoband from "./InputFileCytoband.vue";

export default Vue.extend({
    name: 'InputArgumentsOptional',
    props:{
      value: String,
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
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
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
})
</script>