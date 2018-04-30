HTMLWidgets.widget({

  name: 'igvShiny',

  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
          console.log("---- ~/github/igvShiny/inst/htmlwidgets, renderValue");
          console.log("igv.js renderValue, wh: " + width + ", " + height)
          var igvDiv, options;
          igvDiv = el; // $("#igvDiv")[0];
          options = {locus: "MEF2C",
               minimumBases: 5,
               flanking: 1000,
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
                  height: 30
                  },
                 ]
              }; // options
           igvBrowser = igv.createBrowser(igvDiv, options);
          },
      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
        }

    };
  }
});  // widget
