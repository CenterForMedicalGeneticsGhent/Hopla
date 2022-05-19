<template>
<v-container>
    <v-text-field
    id="input_disease"
    label="Disease (e.g. breast cancer)"  
    dense
    outlined
    v-model="disease"
    type="text"
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
        }
    },
    computed:{
        disease:{
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            },
        },
    },
    methods:{
        //CODE
    },
}
</script>
