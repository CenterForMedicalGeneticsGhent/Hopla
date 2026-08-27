<template>
<v-container>
  <HoplaForm />
</v-container>
</template>

<script lang="ts">
  import HoplaForm from '../components/Forms/FormHopla.vue';

  export default {
    name: 'Home',

    components: {
      HoplaForm,
    },
  }
</script>
