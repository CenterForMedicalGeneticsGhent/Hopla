<template>
    <v-radio-group
    class="ma-0 pa-0"
    v-model="optionChosen"
    dense
    >
      <v-radio
        label="Keep Chromosomes Only"
        :value="0"
      ></v-radio>
      <v-radio
        label="Keep Regions Only"
        :value="1"
      ></v-radio>
    </v-radio-group>
</template>


<script>
var options = [
  "keepChromosomesOnly",
  "keepRegionsOnly",
];

export default {
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
          if (this.keepChromosomesOnly){
            return 0;
          } 
          else {
            return 1;
          }
        },
        set: function(i){
          if (i==0){
            [this.keepChromosomesOnly, this.keepRegionsOnly] = [true,false];
          }
          else {
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
}
</script>
