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
    config: Object,
  },
  data: function() {
    return {

    };
  },
  computed:{
    //code
  },
  methods:{
    //code
  },
  watch:{
    //code
  },  
})
</script>