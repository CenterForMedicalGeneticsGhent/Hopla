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
import InputWindowSizeVoting from "./InputWindowSizeVoting.vue";
import InputKeepChromosomesRegionsOnly from "./InputKeepChromosomesRegionsOnly.vue";

export default {
    name: 'InputArgumentsBAlleleProfiles',
    emits: ['update:modelValue'],
    props:{
        modelValue: Object,
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
      //CODe
    },
}
</script>