<template>
<v-text-field
label="Window Size Voting"
outlined
v-model="windowSizeVoting"
type="number"
@change="handleInput()"
/>
</template>


<script>
export default {
    props:{
        value: Number,
    },
    data: function(){
        return{
            windowSizeVoting: this.value,
            windowSizeVotingOld: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        handleInput: function(){
            var windowSizeVotingNew = Number(this.windowSizeVoting); //If not number it is transformed to 0
            if (windowSizeVotingNew===this.windowSizeVotingOld){
                //Nothing changes, do nothing
            }
            else if (windowSizeVotingNew>0){
                // Valid input
                this.windowSizeVotingOld=windowSizeVotingNew;
                this.$emit('input',windowSizeVotingNew);
            } 
            else {
                //Invalid input, change back to previous value
                this.windowSizeVoting = this.windowSizeVotingOld;
            } 
        },
    },
}
</script>
