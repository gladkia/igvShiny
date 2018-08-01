HTMLWidgets.widget({

  name: 'igvShiny',

  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(options) {
          console.log("---- ~/github/igvShiny/inst/htmlwidgets, renderValue");
          console.log("igv.js renderValue, wh: " + width + ", " + height)
          console.log("--------- options");
          console.log(options)
          var igvDiv;
          igvDiv = el; // $("#igvDiv")[0];
          var fullOptions = {
              locus: options.roi,
              minimumBases: 5,
              flanking: 1000,
              doubleClickDelay: 1,
              showRuler: true,
              reference: {id: "hg38",
                    fastaURL: "https://s3.amazonaws.com/igv.broadinstitute.org/genomes/seq/hg38/hg38.fa",
                 cytobandURL: "https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg38/cytoBandIdeo.txt"
                 },
              tracks: [
                {name: 'Gencode v24',
                      url: "https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg38/genes/gencode.v24.annotation.sorted.gtf.gz",
                 indexURL: "https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg38/genes/gencode.v24.annotation.sorted.gtf.gz.tbi",
                 format: 'gtf',
                 visibilityWindow: 2000000,
                 displayMode: 'EXPANDED',
                 height: 300
                 },
                ]
              }; // fullOptions
           igvBrowser = igv.createBrowser(igvDiv, fullOptions);

           Shiny.addCustomMessageHandler("showGenomicRegion", function(message) {
                window.igvBrowser.search(message.roi);});

           igvBrowser.on('trackclick', function (track, popoverData){
              var x = popoverData;
              if(x.length == 1){
                  if(Object.getOwnPropertyNames(x[0]).includes("value")){
                      var id = x[0].value;
                      console.log("in click handler, id:" + id);
                      if(id.indexOf("rs") == 0){
                         //var url = "https://www.ncbi.nlm.nih.gov/snp/" + rsid;
                         var url = "https://www.ncbi.nlm.nih.gov/projects/SNP/snp_ref.cgi?rs=" + id
                         return " &nbsp; dbSNP: <a href='" + url + "' target=_blank>" + id + "</a>";
                         } // if "^rs"
                      if(id.indexOf("tfbs-snp") == 0){
                         console.log("--- about to contact Shiny")
                         var message = {id: id, date: Date()};
                         var messageName = "trackClick"
                         Shiny.onInputChange(messageName, message);
                         console.log("--- after contacting Shiny")
                         //return "<h4> " + id + "</h4>";
                         } // tfbs-snp
                     } // if a value field
                 } // if just one element
              console.log("click! 810");
              console.log(x);
              //return undefined;   // true, false: default popup disabled; undefined: default popup ensues.
               return undefined;
              });

          },
      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
        }

    };
  }
});  // widget




