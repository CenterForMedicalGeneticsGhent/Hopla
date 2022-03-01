<template>
<v-container>
  <ParseConfig v-model="config" />
</v-container>
</template>

<script>
import Vue from 'vue'

import ParseConfig from "../Parsers/ParseConfig.vue";

export default Vue.extend({
  name: 'TabConfigFile',
  components:{
    ParseConfig,
  },
  props:{
    value: Object,
  },
  data: function() {
    return {
      config: this.value,
    }
  },
  computed:{
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
    }
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