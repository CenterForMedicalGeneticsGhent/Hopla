<template>
<v-container>
    <v-text-field
    id="input_family_id"
    label="Family ID"  
    dense
    outlined
    v-model="famID"
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
        famID: {
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            }
        }
    },
    methods:{
    },
}
</script>
