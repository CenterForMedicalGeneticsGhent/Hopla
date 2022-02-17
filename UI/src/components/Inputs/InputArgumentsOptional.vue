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
            fileCytoband: this.value,
        }
    },
    computed:{
        configWatcher: {
            get: function(){
            return `
                ${JSON.stringify(this.fileCytoband)}
            `;
            }
        },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.fileCytoband);
      },
    },
    mounted:function(){
        //CODE
    },
    watch:{
      configWatcher:{
        handler: function(newVal,oldVal){
          if (oldVal != newVal){
            this.handleInput();
          }
        },
        deep:false,
        immediate:false,
      },
    },
})
</script>