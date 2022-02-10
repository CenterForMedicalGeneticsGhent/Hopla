<template>
<v-container>
</v-container>
</template>

<script>
  import Vue from 'vue'


  export default Vue.extend({
    name: 'Parameters',
    components:{
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
      }
    },
    computed:{
      config: function(){
        return {
        };
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
        immediate:false,
      },
    },  
    })
</script>