<template>
<v-container>
<v-card>
  <v-card-title>
      Remaining Features
  </v-card-title>
  <v-card-text>
    <InputLimitPmToP v-model="limitPmToP" />
    
  </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';

import InputLimitPmToP from "../Inputs/InputLimitPmToP.vue";

export default Vue.extend({
    name: 'InputArgumentsRemainingFeatures',
    props:{
        value: Object,
    },
    components:{
      InputLimitPmToP,
    },
    data: function(){
        return{
          limitPmToP: this.value.limitPmToP,
          valueOfP: this.value.valueOfP,
        }
    },
    computed:{
      config: {
        get: function(){
          return {
            limitPmToP: this.limitPmToP,
          valueOfP: this.valueOfP,
          };
        },
      },
        configWatcher: {
            get: function(){
            return `
                ${JSON.stringify(this.config)}
            `;
            }
        },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
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