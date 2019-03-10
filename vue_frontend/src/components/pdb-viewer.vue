<template>
    <div style="height: 400px; width: 400px; position: relative;" class='viewer_3Dmoljs' data-href="http://monster.northwestern.edu/jobs/27rv13g098/1/AB.pdb"></div>
</template>

<script>
    export default {
        name: "pdb-viewer",
        props: [ 'pdbFile' ],
        mounted: function () {
          $3Dmol.createViewer($(".viewer_3Dmoljs"))
        }
    }
</script>

<style scoped>

</style>
