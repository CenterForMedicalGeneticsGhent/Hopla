<template>
<v-container>
  <v-row>
    
    <v-col class="d-flex justify-center align-center"><v-card
    width="550px"
    >
      <v-card-title> 
        <v-avatar 
        size="48"
        tile
        >
          <img
            alt="user"
            src="../assets/grandparents1.png"
          >
        </v-avatar>
        <v-spacer />
        Maternal Grandparents
        <v-spacer />
      </v-card-title>
    </v-card></v-col>

    <v-col class="d-flex justify-center align-center"><v-card
    width="550px"
    >
      <v-card-title> 
        <v-avatar 
        size="48"
        tile
        >
          <img
            alt="user"
            src="../assets/grandparents2.png"
          >
        </v-avatar>
        <v-spacer />
        Paternal Grandparents 
        <v-spacer />
      </v-card-title>
    </v-card></v-col>
  </v-row>
  
  <v-row>
    <v-col class="d-flex justify-center align-center"><v-card
    width="550px"
    >
      <v-card-title> 
        <v-avatar 
        size="48"
        tile
        >
          <img
            alt="user"
            src="../assets/parents.png"
          >
        </v-avatar>
        <v-spacer />
        Parents 
        <v-spacer />
      </v-card-title>
    </v-card></v-col>
  </v-row>

  <v-row>
    <v-col><v-card>
      <v-card-title> 
        <v-avatar 
        size="48"
        tile
        >
          <img
            alt="user"
            src="../assets/siblings.png"
          >
        </v-avatar>
        <v-spacer />
        Siblings
        <v-spacer />
      </v-card-title>
    </v-card></v-col>
  </v-row>

  <v-row>
    <v-col><v-card>
      <v-card-title> 
        <v-avatar 
        size="48"
        tile
        >
          <img
            alt="user"
            src="../assets/embryo.png"
          >
        </v-avatar>
        <v-spacer />
        Embryos
        <v-spacer />
      </v-card-title>
    </v-card></v-col>
  </v-row>

</v-container>
</template>

<script lang="ts">
  import Vue from 'vue'

  export default Vue.extend({
    name: 'Pedigree',
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