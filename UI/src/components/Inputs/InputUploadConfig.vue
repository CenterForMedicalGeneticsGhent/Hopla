<template>
<v-container>
    <v-file-input
    placeholder="Upload Config"
    dense
    prepend-inner-icon="mdi-upload"
    prepend-icon=""
    rounded
    filled
    @change="upload"
    />
</v-container>
</template>


<script>
export default {
    props:{
        value: Object,
    },
    data: function(){
        return {
            config: this.value,
        }
    },
    computed:{
        //CODE
    },
    methods:{
        upload: function(event){
            var filePath = event.name;
            // create file reader and load text file
            var fileReader=new FileReader();
            fileReader.readAsText(event);
            fileReader.onload=function(){
                console.log(fileReader.result)
            }
        },
    },
}
</script>
