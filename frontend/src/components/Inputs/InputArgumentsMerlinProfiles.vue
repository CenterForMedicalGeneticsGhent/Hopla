<template>
<v-container>
<v-card>
  <v-card-title>
      Merlin Profiles
  </v-card-title>
  <v-card-text>
    <v-row
    align="center"
    justify="center"
    >
        <InputWindowSizeVoting v-model="windowSizeVoting" />
    </v-row>
    <v-row
    align="center"
    justify="center"
    >
        <InputKeepChromosomesRegionsOnly v-model="keepChromosomesRegionsOnly" />
        <v-spacer />
    </v-row>
  </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';
import InputWindowSizeVoting from "./InputWindowSizeVoting.vue";
import InputKeepChromosomesRegionsOnly from "./InputKeepChromosomesRegionsOnly.vue";

export default Vue.extend({
    name: 'InputArgumentsBAlleleProfiles',
    props:{
        value: Object,
    },
    components:{
      InputWindowSizeVoting,
      InputKeepChromosomesRegionsOnly,
    },
    data: function(){
        return{
          windowSizeVoting: this.value.windowSizeVoting,
          keepChromosomesRegionsOnly: this.value.keepChromosomesRegionsOnly,
        }
    },
    computed:{
      config: {
        get: function(){
          return {
            windowSizeVoting: this.windowSizeVoting,
            keepChromosomesRegionsOnly: this.keepChromosomesRegionsOnly,
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