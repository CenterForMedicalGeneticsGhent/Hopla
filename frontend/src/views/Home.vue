<template>
<v-container>
  <Form />
</v-container>
</template>

<script lang="ts">
  import Vue from 'vue'
  import Form from '../components/Form.vue';

  export default Vue.extend({
    name: 'Home',

    components: {
      Form,
    },
  })
</script>
