<template>
<v-container>
    <v-autocomplete
    v-model="inheritance"
    :items="options"
    label="Inheritance"
    outlined
    @change="handleInput()"
    />
</v-container>
</template>


<script>
export default {
    props:{
        value: String,
    },
    data: function(){
        return{
            inheritance: this.value,
            options: [
                'AD',
                'AR',
                'XLD',
                'XLR',
            ],
        }
    },
    computed:{
        //CODE
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.inheritance);
      },
    },
}
</script>
