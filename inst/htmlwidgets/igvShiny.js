HTMLWidgets.widget({

  name: 'igvShiny',
  type: 'output',

  factory: function(el, width, height) {

    var igvWidget = null;

    return {
      renderValue: function(options) {
          console.log("---- ~/github/igvShiny/inst/htmlwidgets, renderValue");
          console.log("     el: ");
          console.log(el);
          console.log("igv.js renderValue, wh: " + width + ", " + height)
          console.log("--------- options");
          console.log(options)
          var igvDiv;
          igvDiv = el; // $("#igvDiv")[0];
          var fullOptions = genomeSpecificOptions(options.genomeName, options.initialLocus)

         igv.createBrowser(igvDiv, fullOptions)
             .then(function (browser) {
                igvWidget = browser;
                window.igvBrowser = igvWidget;
                igvWidget.on('trackclick', function (track, popoverData){
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
               return undefined;
              }); // on

             }); // then: promise fulflled
             // igvWidget = igv.createBrowser(igvDiv, fullOptions);
           Shiny.addCustomMessageHandler("showGenomicRegion", function(message) {
               //window.igvBrowser.search(message.roi);
              console.log(message)
              igvWidget.search(message.region)
              });


          },
      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
        }

    }; // return
  }  // factory
});  // widget
//------------------------------------------------------------------------------------------------------------------------
function genomeSpecificOptions(genomeName, initialLocus)
{
    var hg19_options = {
     locus: initialLocus,
     flanking: 1000,
     showRuler: true,
     minimumBases: 5,

     reference: {id: "hg19"},
     tracks: [
        {name: 'Gencode v18',
              url: "https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg19/genes/gencode.v18.collapsed.bed",
         indexURL: "https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg19/genes/gencode.v18.collapsed.bed.idx",
         visibilityWindow: 2000000,
         displayMode: 'EXPANDED'
         }
        ]
     }; // hg19_options


    var hg38_options = {
     locus: initialLocus,
     minimumBases: 5,
     flanking: 1000,
     showRuler: true,

	reference: {
	    id: "hg38",
	    fastaURL: "https://s3.amazonaws.com/igv.broadinstitute.org/genomes/seq/hg38/hg38.fa",
            cytobandURL: "https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg38/cytoBandIdeo.txt"
            },
     tracks: [
        {name: 'Gencode v24',
         url: "//s3.amazonaws.com/igv.broadinstitute.org/annotations/hg38/genes/gencode.v24.annotation.sorted.gtf.gz",
         indexURL: "//s3.amazonaws.com/igv.broadinstitute.org/annotations/hg38/genes/gencode.v24.annotation.sorted.gtf.gz.tbi",
         format: 'gtf',
         visibilityWindow: 2000000,
         displayMode: 'EXPANDED',
         height: 300
         },
        ]
     }; // hg38_options


   var mm10_options = {
         locus: initialLocus,
         flanking: 2000,
	 showKaryo: false,
         showNavigation: true,
         minimumBases: 5,
         showRuler: true,
         reference: {id: "mm10",
                     fastaURL: "http://igv-data.systemsbiology.net/static/mm10/GRCm38.primary_assembly.genome.fa",
                     cytobandURL: "http://igv-data.systemsbiology.net/static/mm10/cytoBand.txt"
                     },
         tracks: [
            {name: 'Gencode vM14',
             url: "http://igv-data.systemsbiology.net/static/mm10/gencode.vM14.basic.annotation.sorted.gtf.gz",
             indexURL: "http://igv-data.systemsbiology.net/static/mm10/gencode.vM14.basic.annotation.sorted.gtf.gz.tbi",
             indexed: true,
             type: 'annotation',
             format: 'gtf',
             visibilityWindow: 2000000,
             displayMode: 'EXPANDED',
             height: 300,
             searchable: true
             },
            ]
       }; // mm10_options

   var tair10_options = {
         locus: initialLocus,
         flanking: 2000,
	 showKaryo: false,
         showNavigation: true,
         minimumBases: 5,
         showRuler: true,
         reference: {id: "TAIR10",
                fastaURL: "http://igv-data.systemsbiology.net/static/tair10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa",
                indexURL: "http://igv-data.systemsbiology.net/static/tair10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.fai",
                aliasURL: "http://igv-data.systemsbiology.net/static/tair10/chromosomeAliases.txt"
                },
         tracks: [
           {name: 'Genes TAIR10',
            type: 'annotation',
            visibilityWindow: 500000,
            url: "http://igv-data.systemsbiology.net/static/tair10/TAIR10_genes.sorted.chrLowered.gff3.gz",
            color: "darkred",
            indexed: true,
            height: 200,
            displayMode: "EXPANDED"
            },
            ]
          }; // tair10_options

   var rhos_options = {
         locus: initialLocus,
         flanking: 2000,
	 showKaryo: false,
         showNavigation: true,
         minimumBases: 5,
         showRuler: true,
         reference: {id: "Rhodobacter sphaeroides",
                     fastaURL: "http://igv-data.systemsbiology.net/static/rhos/GCF_000012905.2_ASM1290v2_genomic.fna",
                     indexURL: "http://igv-data.systemsbiology.net/static/rhos/GCF_000012905.2_ASM1290v2_genomic.fna.fai"
                },
         tracks: [
           {name: 'Genes',
            type: 'annotation',
            visibilityWindow: 500000,
            url: "http://igv-data.systemsbiology.net/static/rhos/GCF_000012905.2_ASM1290v2_genomic.gff.gz",
            color: "darkred",
            indexed: true,
            height: 200,
            displayMode: "EXPANDED"
            },
            ]
          }; // rhos_options

   var igvOptions = null;

   switch(genomeName) {
      case "hg19":
         igvOptions = hg19_options;
         break;
      case "hg38":
         igvOptions = hg38_options;
         break;
       case "mm10":
         igvOptions = mm10_options;
         break;
       case "tair10":
         igvOptions = tair10_options;
         break;
       case "rhos":
         igvOptions = rhos_options;
         break;
         } // switch on genomeName

    return(igvOptions)

} // genomeSpecificOptions
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("removeTracksByName",

   function(message){
       var trackNames = message.trackNames;
       console.log("=== removeTracksByName")
       console.log(trackNames)
       if(typeof(trackNames) == "string")
           trackNames = [trackNames];
       var count = window.igvBrowser.trackViews.length;

       for(var i=(count-1); i >= 0; i--){
          var trackView = window.igvBrowser.trackViews[i];
          var trackViewName = trackView.track.name;
          var matched = trackNames.indexOf(trackViewName) >= 0;
          //console.log(" is " + trackViewName + " in " + JSON.stringify(trackNames) + "? " + matched);
          if (matched){
             window.igvBrowser.removeTrack(trackView.track);
             } // if matched
          } // for i

})  // removeTrackByName
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedTrackFromFile",

   function(message){
      console.log("=== loadBedTrackFile");
      console.log(message);

       var uri = window.location.href + "tracks/" + message.filename;
       var config = {format: "bed",
                     name: "feature test",
                     url: uri,
                     type: "annotation",
                     indexed: false,
                     displayMode: "EXPANDED",
                     sourceType: "file",
                     color: "lightGreen",
		     height: 50
                     };
      window.igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedTrack",

   function(message){
      console.log("=== loadBedTrack");
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;

      var config = {format: "bed",
                    name: trackName,
                    type: "annotation",
                    features: tbl,
                    indexed: false,
                    displayMode: "EXPANDED",
                    color: color,
                    height: trackHeight
                    };
      window.igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedGraphTrack",

   function(message){
      console.log("=== loadBedGraphTrack");
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;

      var config = {format: "bedgraph",
                    name: trackName,
                    type: "wig",
                    features: tbl,
                    indexed: false,
                    displayMode: "EXPANDED",
                    //sourceType: "file",
                    color: color,
                    height: trackHeight
                    };
      window.igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadSegTrack",

   function(message){
      console.log("=== loadSegTrack");
      var trackName = message.trackName;
      var bedFeatures = message.tbl;

      var config = {format: "bed",
                    name: trackName,
                    type: "seg",
                    features: bedFeatures,
                    indexed: false,
                    displayMode: "EXPANDED",
                    //sourceType: "file",
                    color: "red",
                    height: 50
                    };
      window.igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
