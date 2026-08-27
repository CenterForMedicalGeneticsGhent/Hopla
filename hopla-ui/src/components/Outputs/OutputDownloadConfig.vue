<template>
<v-btn
color="primary"
density="compact"
@click="downloadFile()"
>
    Download
</v-btn>
</template>


<script>

export default {
    name: "OutputDownloadConfig",
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
            var text = this.textToDownload || "";
            var fileName = (this.fileNameDefault || "hopla-config.yaml")
                .replace(/[^A-Za-z0-9._-]/g, "_")
                .replace(/^\.+/, "");
            if (fileName.length === 0) {
                fileName = "hopla-config.yaml";
            }
            // make blob from text
            var blob = new Blob([text], { type: "application/yaml;charset=utf-8" });
            // create object url
            var url = URL.createObjectURL(blob);
            
            // download file
            var elm = document.createElement("a");
            elm.href=url; //give url to download
            elm.setAttribute("download", fileName);//set default download name
            elm.click();
            elm.remove();
            URL.revokeObjectURL(url);
        },
    },
    watch:{
        //code
    },
    mounted: function(){
        //code
    }
}
</script>