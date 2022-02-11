<template>
<v-container>
  {{ config }}
</v-container>
</template>

<script>
  import Vue from 'vue'


  export default Vue.extend({
    name: 'TabConfigFile',
    components:{
    },
    props:{
      config: Object,
    },
    data: function() {
      return {
      }
    },
    computed:{
    },
    methods:{
    },
    watch:{
    },  
    })
</script>