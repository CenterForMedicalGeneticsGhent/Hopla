<template>
<v-container>
  <v-row
  align="center"
  justify="center"  
  >
    <v-col class="d-flex justify-center align-center">
    </v-col>
    <v-col class="d-flex justify-center align-center">
    </v-col>
    <v-col class="d-flex justify-center align-center">
    </v-col>
  </v-row>
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'

  export default Vue.extend({
    name: 'TabAdvanced',
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
        immediate:true,
      },
    },  
    })
</script>