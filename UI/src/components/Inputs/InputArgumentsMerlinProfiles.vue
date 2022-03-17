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
        <InputWindowSizeVoting v-model="config.windowSizeVoting" />
    </v-row>
    <v-row
    align="center"
    justify="center"
    >
        <InputKeepChromosomesRegionsOnly v-model="config.keepChromosomesRegionsOnly" />
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
        }
    },
    computed:{
      config:{
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
      //CODe
    },
})
</script>