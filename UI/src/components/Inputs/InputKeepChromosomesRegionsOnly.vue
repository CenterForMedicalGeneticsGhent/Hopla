<template>
    <v-radio-group
    class="ma-0 pa-0"
    v-model="optionChosen"
    dense
    >
      <v-radio
        label="Show everything"
        :value="0"
      ></v-radio>
      <v-radio
        label="Only show chromosome of interest"
        :value="1"
      ></v-radio>
      <v-radio
        label="Only show region of interest"
        :value="2"
      ></v-radio>
    </v-radio-group>
</template>


<script>
import Vue from 'vue';


export default Vue.extend({
    name:"InputKeepChromosomesRegionsOnly",
    props:{
        value: Object,
    },
    data: function(){
      return {
        keepChromosomesOnly: this.value.keepChromosomesOnly,
        keepRegionsOnly: this.value.keepRegionsOnly,
      }
    },
    computed:{
      optionChosen:{
        get: function(){
          if ((!this.keepChromosomesOnly) && (!this.keepRegionsOnly)){
            return 0;
          } 
          else if ((this.keepChromosomesOnly) && (!this.keepRegionsOnly)){
            return 1;
          }
          else if ((!this.keepChromosomesOnly) && (this.keepRegionsOnly)){
            return 2;
          }
          else {
            return 0;
          }
        },
        set: function(i){
          if (i==0){
            [this.keepChromosomesOnly, this.keepRegionsOnly] = [false,false];
          }
          else if (i==1){
            [this.keepChromosomesOnly, this.keepRegionsOnly] = [true,false];
          }
          else if (i==2){
            [this.keepChromosomesOnly, this.keepRegionsOnly] = [false,true];
          }
        }
      },
      config: function(){
        return {
          keepChromosomesOnly: this.keepChromosomesOnly,
          keepRegionsOnly: this.keepRegionsOnly,
        }
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
    mounted: function(){
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
        immediate:true,
      },
    }, 
})
</script>
