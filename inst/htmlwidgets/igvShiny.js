//----------------------------------------------------------------------------------------------------
// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
// from david nemes: https://gist.github.com/nmsdvid/8807205
// used below in the locuschange handler
function debounce(func, wait, immediate) {
   var timeout;
   return function() {
     var context = this, args = arguments;
       clearTimeout(timeout);
       timeout = setTimeout(function() {
	   timeout = null;
	   if (!immediate) func.apply(context, args);
       }, wait);
       if (immediate && !timeout) func.apply(context, args);
   };
} // debounce
//----------------------------------------------------------------------------------------------------
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
         console.log("---- el");
         console.log(el);
         console.log(el.id)
         var htmlContainerID = el.id;
         var fullOptions = genomeSpecificOptions(options.genomeName, options.initialLocus,
                                                 options.displayMode, parseInt(options.trackHeight))

         console.log("about to createBrowser, trackHeight: " + fullOptions.height)
         igv.createBrowser(igvDiv, fullOptions)
             .then(function (browser) {
                console.log("createBrowser promise fulfilled");
                igvWidget = browser;
                console.log("about to save igv browser");
                document.getElementById(htmlContainerID).igvBrowser = browser;
                document.getElementById(htmlContainerID).chromLocString = options.initialLocus;
                jqueryTag = "#" + htmlContainerID + " .igv-root";
                console.log("jqueryTag: " + jqueryTag);
                igvRoots = $(jqueryTag);
                if(igvRoots.length > 1){
                   igvRoots[0].remove()
                   }
                console.log(" count: " + igvRoots.length);
                igvWidget.on('locuschange', debounce(function (referenceFrame){
                   console.log("---- locuschange, referenceFrame: ")
                   console.log(referenceFrame);
                   var chromLocString = referenceFrame.label
                   document.getElementById(htmlContainerID).chromLocString = chromLocString;
                   var eventName = "currentGenomicRegion." + htmlContainerID
                   console.log("--- calling Shiny.setInputValue:");
   		   console.log("eventName: " + eventName);
                   console.log("chromLocString: " + chromLocString);
                   Shiny.setInputValue(eventName, chromLocString, {priority: "event"});
                   var moduleEventName = "igv-currentGenomicRegion." + htmlContainerID.replace("igv-", "");
   		   console.log("moduleEventName: " + moduleEventName);
                   Shiny.setInputValue(moduleEventName, chromLocString, {priority: "event"});
                 }, 250, false));
                igvWidget.on('trackclick', function (track, popoverData){
                   var x = popoverData;
                   console.log(x)
                       // prepend "igv-" to support the github/shinyModules/igvModule.R
                   Shiny.setInputValue("igv-trackClick", x, {priority: "event"})
                       // for use outside of the ShinyModule idiom
                   Shiny.setInputValue("trackClick", x, {priority: "event"})
                   return false; // undefined causes follow on display of standard popup
                   }); // on
                Shiny.setInputValue("igvReady", htmlContainerID, {priority: "event"});
                Shiny.setInputValue("igv-igvReady", htmlContainerID, {priority: "event"});
                }); // then: promise fulflled
          },
      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
        }

    }; // return
  }  // factory
});  // widget
//------------------------------------------------------------------------------------------------------------------------
function genomeSpecificOptions(genomeName, initialLocus, displayMode, trackHeight)
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
         displayMode: displayMode
         }
        ]
     }; // hg19_options


    var hg38_options = {
       locus: initialLocus,
       height: 200,
       //autoHeight: true,
       minimumBases: 5,
       flanking: 1000,
	name: "foo",
       showRuler: true,
       genome: "hg38"
       }; // hg38_options


   var mm10_options = {
      locus: initialLocus,
      flanking: 2000,
      minimumBases: 5,
      showRuler: true,
      genome: "mm10"
      }; // mm10_options

   var tair10_options = {
         locus: initialLocus,
         flanking: 2000,
	 showKaryo: false,
         showNavigation: true,
         minimumBases: 5,
         showRuler: true,
         reference: {id: "TAIR10",
                fastaURL: "https://igv-data.systemsbiology.net/static/tair10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa",
                indexURL: "https://igv-data.systemsbiology.net/static/tair10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.fai",
                aliasURL: "https://igv-data.systemsbiology.net/static/tair10/chromosomeAliases.txt"
                },
         tracks: [
           {name: 'Genes TAIR10',
            type: 'annotation',
            visibilityWindow: 500000,
            url: "https://igv-data.systemsbiology.net/static/tair10/TAIR10_genes.sorted.chrLowered.gff3.gz",
            color: "darkred",
            indexed: true,
            height: trackHeight,
            displayMode: displayMode
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
                     fastaURL: "https://igv-data.systemsbiology.net/static/rhos/GCF_000012905.2_ASM1290v2_genomic.fna",
                     indexURL: "https://igv-data.systemsbiology.net/static/rhos/GCF_000012905.2_ASM1290v2_genomic.fna.fai"
                },
         tracks: [
           {name: 'Genes',
            type: 'annotation',
            visibilityWindow: 500000,
            url: "https://igv-data.systemsbiology.net/static/rhos/GCF_000012905.2_ASM1290v2_genomic.gff.gz",
            color: "darkred",
            indexed: true,
            height: trackHeight,
            displayMode: displayMode
            },
            ]
          }; // rhos_options

   var igvOptions = null;

   switch(genomeName) {
      case "hg19":
         igvOptions = hg19_options;
         break;
      case "hg38":
         console.log("hg38 options, trackHeight: " + hg38_options.height);
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
Shiny.addCustomMessageHandler("redrawIgvWidget",

    function(message) {
        console.log("--- redrawIgvShiny")
        window.igvBrowser.resize();
        window.igvBrowser.visibilityChange();
        });

//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("showGenomicRegion",

    function(message) {
        var elementID = message.elementID;
        var igvBrowser = document.getElementById(elementID).igvBrowser;
        igvBrowser.search(message.region)
        document.getElementById(elementID).chromLocString = message.region;
        });

//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("getGenomicRegion",

    function(message) {
       var elementID = message.elementID;
       var currentValue = document.getElementById(elementID).chromLocString;
       console.log("current chromLocString: " + currentValue)
       var eventName = "currentGenomicRegion." + elementID;
       //console.log("--- calling Shiny.setInputValue:");
       //console.log("eventName: " + eventName);
       //console.log("chromLocString: " + currentValue)
       Shiny.setInputValue(eventName, currentValue, {priority: "event"});
       var moduleEventName = "igv-currentGenomicRegion." + elementID.replace("igv-", "");
       console.log("moduleEventName: " + moduleEventName);
       Shiny.setInputValue(moduleEventName, currentValue, {priority: "event"});
       })

//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("removeTracksByName",

   function(message){
       var elementID = message.elementID;
       var igvBrowser = document.getElementById(elementID).igvBrowser;
       var trackNames = message.trackNames;
       console.log("=== removeTracksByName")
       console.log(trackNames)
       if(typeof(trackNames) == "string")
           trackNames = [trackNames];
       var count = igvBrowser.trackViews.length;

       for(var i=(count-1); i >= 0; i--){
          var trackView = igvBrowser.trackViews[i];
          var trackViewName = trackView.track.name;
          var matched = trackNames.indexOf(trackViewName) >= 0;
          console.log(" is " + trackViewName + " in " + JSON.stringify(trackNames) + "? " + matched);
          if (matched){
             igvBrowser.removeTrack(trackView.track);
             } // if matched
          } // for i

})  // removeTrackByName
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedTrackFromFile",

   function(message){
       console.log("=== loadBedTrackFile");
       console.log(message);
       var elementID = message.elementID;
       var igvBrowser = document.getElementById(elementID).igvBrowser;

       var uri = window.location.href + "tracks/" + message.filename;
       var config = {format: "bed",
                     name: "feature test",
                     url: uri,
                     type: "annotation",
                     order: Number.MAX_VALUE,
                     indexed: false,
                     displayMode: "EXPANDED",
                     sourceType: "file",
                     color: "lightGreen",
		     height: 50
                     };
      igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedTrack",

   function(message){
      console.log("=== loadBedTrack");
      console.log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;

      var config = {format: "bed",
                    name: trackName,
                    type: "annotation",
                    order: Number.MAX_VALUE,
                    features: tbl,
                    indexed: false,
                    displayMode: "EXPANDED",
                    color: color,
                    height: trackHeight
                    };
      igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedGraphTrack",

   function(message){
      //console.log("=== loadBedGraphTrack");
      //console.log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;
      var autoscale = message.autoscale;
      var min = message.min;
      var max = message.max;

      var config = {format: "bedgraph",
                    name: trackName,
                    type: "wig",
                    order: Number.MAX_VALUE,
                    features: tbl,
                    indexed: false,
                    displayMode: "EXPANDED",
                    color: color,
                    height: trackHeight,
                    autoscale: autoscale,
                    min: min,
                    max: max
                    };
      igvBrowser.loadTrack(config);
      }

);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadSegTrack",

   function(message){
      console.log("=== loadSegTrack");
      console.log(message);
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var bedFeatures = message.tbl;
      console.log("--- about to assign seg config")

      var config = {format: "seg",
                    name: trackName,
                    type: "seg",
                    order: Number.MAX_VALUE,
                    features: bedFeatures,
                    indexed: false,
                    displayMode: "EXPANDED",
                    //sourceType: "file",
                    color: "red",
                    height: 50
                    };
      console.log("--- about to  loadTrack seg")
      igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadVcfTrack",

   function(message){

      console.log("=== loadVcfTrack");
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var vcfFile = message.vcfDataFilepath;
      var dataURL = window.location.href + message.vcfDataFilepath;
      console.log("dataURL: " + dataURL);

      var config = {format: "vcf",
                     name: trackName,
                     url: dataURL,
                     order: Number.MAX_VALUE,
                     indexed: false,
                     displayMode: "EXPANDED",
                     sourceType: "file",
                     height: 100,
                     visibilityWindow: 1000000,
                     //homvarColor: homvarColor,
                     //hetvarColor: hetvarColor,
                     //homrefColor: homrefColor,
                     //color: locationColor,
                     type: "variant"
                    };


       igvBrowser.loadTrack(config);
       }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadGwasTrack",

   function(message){

      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;
      var autoscale = message.autoscale;
      var min = message.min;
      var max = message.max;

      var gwasFile = message.gwasDataFilepath;
      var dataURL = window.location.href + gwasFile;
      console.log("dataURL: " + dataURL);
      // debugger;

      var config = {format: "gwas",
                    type: "gwas",
                    name: trackName,
                    order: Number.MAX_VALUE,
		    url: dataURL,
                    indexed: false,
                    displayMode: "EXPANDED",
                    height: trackHeight,
                    autoscale: autoscale,
                    min: min,
                    max: max
                    };
      igvBrowser.loadTrack(config);
      }

); // loadGwasTrack
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBamTrackFromURL",

   function(message){
      console.log("=== loadBamTrack");
      console.log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var bamFile = message.bam;
      var baiFile = message.index;

      var config = {format: "bam",
                    name: trackName,
                    url: bamFile,
                    indexURL: baiFile,
                    type: "alignment",
		    order: Number.MAX_VALUE
                    };
      igvBrowser.loadTrack(config);
      }

);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBamTrackFromLocalData",

   function(message){
      console.log("=== loadBamTrackFromLocalData");
      console.log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var dataURL = window.location.href + message.bamDataFilepath;
      var trackName = message.trackName;

      var config = {format: "bam",
                    name: trackName,
                    url: dataURL,
                    type: "alignment",
  		    order: Number.MAX_VALUE
                    };
      igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadCramTrackFromURL",

   function(message){
      console.log("=== loadCramTrackFromURL");
      console.log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var cram = message.cram;
      var index = message.index

      var config = {format: "cram",
                    name: trackName,
                    url: cram,
                    indexURL: index,
                    type: "alignment",
		    order: Number.MAX_VALUE
                    };
      igvBrowser.loadTrack(config);
      }

);
//------------------------------------------------------------------------------------------------------------------------
