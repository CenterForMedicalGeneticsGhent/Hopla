<template>
<v-btn
color="primary"
dense
@click="downloadFile()"
>
    Download
</v-btn>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        textToDownload: String,
        fileNameDefault:String,
    },
    components: {
        //code
    },
    data: function(){
        return {
        }
    },
    computed:{
        //code
    },  
    methods:{
        downloadFile: function(){
            // Params
            var text = this.textToDownload; 
            var fileName = this.fileNameDefault;
            // make blob from text
            var blob = new Blob([text]);
            // create object url
            var url = URL.createObjectURL(blob);
            
            // download file
            var elm = document.createElement("a");
            elm.href=url; //give url to download
            elm.setAttribute("download", fileName);//set default download name
            elm.click();
            elm.remove();
        },
    },
    watch:{
        //code
    },
    mounted: function(){
        //code
    }
})
</script>