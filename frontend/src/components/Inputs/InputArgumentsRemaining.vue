<template>
<v-container>
<v-card>
  <v-card-title>
      Remaining Features
  </v-card-title>
  <v-card-text>
    <v-row
    align="center"
    justify="center"
    >
    </v-row>

    <v-row
    align="center"
    justify="center"
    >
    </v-row>
  </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';

export default Vue.extend({
    name: 'InputArgumentsRemainingFeatures',
    props:{
        value: Object,
    },
    components:{
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