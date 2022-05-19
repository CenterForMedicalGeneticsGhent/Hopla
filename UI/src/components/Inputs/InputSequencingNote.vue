<template>
<v-container>
    <v-text-field
    id="input_sequencing_note"
    label="Sequencing Note"  
    dense
    outlined
    v-model="sequencingNote"
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
        sequencingNote:{
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
