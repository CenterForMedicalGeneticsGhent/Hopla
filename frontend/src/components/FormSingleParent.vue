<template>
  <v-card-text> {{ config }} </v-card-text>
</template>

<script lang="ts">
  import Vue from 'vue'

  export default Vue.extend({
    name: 'FormSingleParent',
    props:{
      value: Object,
    },
    data: function() {
      return {
        config: this.value,
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.config);
      }
    },
  })
</script>