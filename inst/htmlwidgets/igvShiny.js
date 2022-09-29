//----------------------------------------------------------------------------------------------------
var executionMode = "devel";
//executionMode = "production";
const igvshiny_log = function(msg)
{
  if(executionMode == "devel")
      console.log(msg);
}
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
         igvshiny_log("---- ~/github/igvShiny/inst/htmlwidgets, renderValue");
         igvshiny_log("     el: ");
         igvshiny_log(el);
         igvshiny_log("igv.js renderValue, wh: " + width + ", " + height)
         igvshiny_log("--------- options");
         igvshiny_log(options)
         var igvDiv;
         igvDiv = el; // $("#igvDiv")[0];
         igvshiny_log("---- el");
         igvshiny_log(el);
         igvshiny_log(el.id)
         var htmlContainerID = el.id;
         igvshiny_log("fasta: " + options.fasta)
         igvshiny_log("index: " + options.fastaIndex)
         //debugger;
         var fullOptions = genomeSpecificOptions(options.genomeName,
                                                 options.stockGenome,
                                                 options.dataMode,
                                                 options.initialLocus,
                                                 options.displayMode,
                                                 parseInt(options.trackHeight),
                                                 options.fasta,
                                                 options.fastaIndex,
                                                 options.annotation,
                                                 options.moduleNS)

         igvshiny_log("about to createBrowser, trackHeight: " + fullOptions.height)
         igv.createBrowser(igvDiv, fullOptions)
             .then(function (browser) {
                igvshiny_log("createBrowser promise fulfilled");
                igvWidget = browser;
                window.chromLocString = "";
                igvshiny_log("about to save igv browser");
                document.getElementById(htmlContainerID).igvBrowser = browser;
                document.getElementById(htmlContainerID).chromLocString = options.initialLocus;
                jqueryTag = "#" + htmlContainerID + " .igv-root";
                igvshiny_log("jqueryTag: " + jqueryTag);
                igvRoots = $(jqueryTag);
                if(igvRoots.length > 1){
                   igvRoots[0].remove()
                   }
                igvshiny_log(" count: " + igvRoots.length);
                igvWidget.on('locuschange', debounce(function (referenceFrame){
                   igvshiny_log("---- locuschange, referenceFrame: ")
                   igvshiny_log(referenceFrame);
                   var chrom = referenceFrame[0].chr
                   var start = Math.round(referenceFrame[0].start)
		   var end = Math.round(referenceFrame[0].end)
                   var chromLocString = chrom + ":" + start + "-" + end;
                   
                   document.getElementById(htmlContainerID).chromLocString = chromLocString;
                   var eventName = "currentGenomicRegion." + htmlContainerID
                   igvshiny_log("--- calling Shiny.setInputValue:");
   		   igvshiny_log("eventName: " + eventName);
                   igvshiny_log("chromLocString:        " + chromLocString);
                   igvshiny_log("window.chromLocString: " + window.chromLocString);
                   var newRegion = chromLocString != window.chromLocString;
                   igvshiny_log("--- new.loc? " + newRegion);
                   if(newRegion){
                      igvshiny_log("--- generating currentGenomicRegion event: " + chromLocString)
                      Shiny.setInputValue(eventName, chromLocString, {priority: "event"});
                      var moduleEventName = moduleNamespace(options.moduleNS, "currentGenomicRegion.") + htmlContainerID.replace(options.moduleNS, "");
                      if(moduleEventName != eventName){
                         igvshiny_log("moduleEventName: " + moduleEventName);
                         Shiny.setInputValue(moduleEventName, chromLocString, {priority: "event"});
                         }
                   window.chromLocString = chromLocString;
                      } // if new chromLocString
                 }, 250, false));
                igvWidget.on('trackclick', function (track, popoverData){
                   var x = popoverData;
                   igvshiny_log("--- trackclikc");
                   //igvshiny_log(x)
                       // prepend module namespace to support the github/shinyModules/igvModule.R
                   Shiny.setInputValue(moduleNamespace(options.moduleNS, "trackClick"), x, {priority: "event"})
                       // for use outside of the ShinyModule idiom
                   Shiny.setInputValue("trackClick", x, {priority: "event"})
                   //return false; // undefined causes follow on display of standard popup
                   }); // on
                Shiny.setInputValue("igvReady", htmlContainerID, {priority: "event"});
                Shiny.setInputValue(moduleNamespace(options.moduleNS, "igvReady"), htmlContainerID, {priority: "event"});
                }); // then: promise fulflled
          },
      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
        }

    }; // return
  }  // factory
});  // widget
//------------------------------------------------------------------------------------------------------------------------
function moduleNamespace(ns, nameEvent)
{
  return(ns + nameEvent)
}
//------------------------------------------------------------------------------------------------------------
function genomeSpecificOptions(genomeName, stockGenome, dataMode, initialLocus, displayMode, trackHeight,
                               fasta, fastaIndex, annotation, moduleNS)
{
    var localCustomGenome_options = {
        locus: initialLocus,
        flanking: 1000,
        showRuler: true,
        minimumBases: 5,
        reference:{
            id: genomeName,
            fastaURL: window.location.href + fasta,
            indexURL: window.location.href + fastaIndex,
            indexed:  (fastaIndex == null)  ? false : true
            }
        }; // localCustomGenome_options

    var remoteCustomGenome_options = {
        locus: initialLocus,
        flanking: 1000,
        showRuler: true,
        minimumBases: 5,
        
        reference: {
            id: genomeName,
            fastaURL: fasta,
            indexURL: fastaIndex,
            indexed:  (fastaIndex == null)  ? false : true
            }
        }; // remoteCustomGenome_options

    if(annotation != null){
        var annotationTrack = {
            "type": "annotation",
            "format": "gff3",
            "name": "GENES",
            "height": 200,
            "order": Number.MAX_VALUE}
        if(dataMode == "http"){
           remoteCustomGenome_options.reference.tracks = [annotationTrack];
           remoteCustomGenome_options.reference.tracks[0].url = annotation;
           }
        if(dataMode == "localFiles"){
           localCustomGenome_options.reference.tracks = [annotationTrack];
           localCustomGenome_options.reference.tracks[0].url = window.location.href + annotation;
           }
        } // if annotation (gff3) supplied
    
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
            }]
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
            }
        ]
    }; // rhos_options
    
    var igvOptions = null;
    
    switch(genomeName) {
    case "hg19":
        igvOptions = hg19_options;
        break;
    case "hg38":
        igvshiny_log("hg38 options, trackHeight: " + hg38_options.height);
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

    if(!stockGenome){
       switch(dataMode){
       case "http":
          igvOptions = remoteCustomGenome_options;
          break;
       case "localFiles":
          igvOptions = localCustomGenome_options;
          break;
          }
       } // switch on dataMode, for a non-stock (custom) genome
    
    return(igvOptions)

} // genomeSpecificOptions
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("redrawIgvWidget",

    function(message) {
        igvshiny_log("--- redrawIgvShiny")
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
       igvshiny_log("current chromLocString: " + currentValue)
       var eventName = "currentGenomicRegion." + elementID;
       igvshiny_log("--- calling Shiny.setInputValue:");
       igvshiny_log("eventName: " + eventName);
       igvshiny_log("chromLocString: " + currentValue)
       Shiny.setInputValue(eventName, currentValue, {priority: "event"});
       var moduleEventName = "igv-currentGenomicRegion." + elementID.replace("igv-", "");
       igvshiny_log("moduleEventName: " + moduleEventName);
       Shiny.setInputValue(moduleEventName, currentValue, {priority: "event"});
       })

//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("removeTracksByName",

   function(message){
       var elementID = message.elementID;
       var igvBrowser = document.getElementById(elementID).igvBrowser;
       var trackNames = message.trackNames;
       igvshiny_log("=== removeTracksByName")
       igvshiny_log(trackNames)
       if(typeof(trackNames) == "string")
           trackNames = [trackNames];
       var count = igvBrowser.trackViews.length;

       for(var i=(count-1); i >= 0; i--){
          var trackView = igvBrowser.trackViews[i];
          var trackViewName = trackView.track.name;
          var matched = trackNames.indexOf(trackViewName) >= 0;
          igvshiny_log(" is " + trackViewName + " in " + JSON.stringify(trackNames) + "? " + matched);
          if (matched){
             igvBrowser.removeTrack(trackView.track);
             } // if matched
          } // for i

})  // removeTrackByName
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedTrackFromFile",

   function(message){
       igvshiny_log("=== loadBedTrackFile");
       igvshiny_log(message);
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
Shiny.addCustomMessageHandler("loadGenomeAnnotationTrackFromFile",

   function(message){
       igvshiny_log("=== loadGenomeAnnotationTrackFromFile");
       igvshiny_log(message);
       var elementID = message.elementID;
       var igvBrowser = document.getElementById(elementID).igvBrowser;

       var uri = window.location.href + "tracks/" + message.filename;
       var config = {format: "gff3",
                     name: "gff3 track",
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
      igvshiny_log("=== loadBedTrack");
      igvshiny_log(message)
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
      igvshiny_log("=== loadBedGraphTrack");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;
      var autoscale = message.autoscale;
      var autoscaleGroup = message.autoscaleGroup;
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
      if(autoscaleGroup >= 0)
          config['autoscaleGroup'] = autoscaleGroup;
      console.log("--- loading bedGraphTrack");
      console.log(config)
      igvBrowser.loadTrack(config);
      }

);
//------------------------------------------------------------------------------------------------------------------------
//Shiny.addCustomMessageHandler("loadBedGraphTrackFromURL",
Shiny.addCustomMessageHandler("fubar",

   function(message){
      igvshiny_log("=== loadBedGraphTrackFromURL");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var tbl = message.tbl;
      var color = message.color;
      var trackHeight = message.trackHeight;
      var autoscale = message.autoscale;
      var autoscaleGroup = message.autoscaleGroup;
      var min = message.min;
      var max = message.max;
      var url = message.url;       

      var config = {//format: "bigWig",
                    name: trackName,
                    //type: "wig",
                    order: Number.MAX_VALUE,
                    url: url,
                    color: color,
                    height: trackHeight,
                    autoscaleGroup: "1" //autoscaleGroup
                    };
       config = {url: 'https://www.encodeproject.org/files/ENCFF000ASF/@@download/ENCFF000ASF.bigWig',
                 name: 'GM12878 H3K4me3',
                 color: 'rgb(200,0,0)',
                 autoscaleGroup: '1'
                 //order: Number.MAX_VALUE
                 },


      //if(autoscaleGroup >= 0)
      //    config['autoscaleGroup'] = autoscaleGroup;
      console.log("--- loading bedGraphTrackFromURL");
      console.log(config)
      igvBrowser.loadTrack(config).then(function(newTrack){alert("Track loaded: " + newTrack.name);});
      }

); // loadBedGraphTrackFromURL
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadSegTrack",

   function(message){
      igvshiny_log("=== loadSegTrack");
      igvshiny_log(message);
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var bedFeatures = message.tbl;
      igvshiny_log("--- about to assign seg config")

      var config = {type: "seg",
		    format: "seg",
                    name: trackName,
                    order: Number.MAX_VALUE,
                    features: bedFeatures,
                    indexed: false,
                    displayMode: "EXPANDED",
                    //sourceType: "file",
                    height: 50
                    };
      igvshiny_log("--- about to  loadTrack seg")
      igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadVcfTrack",

   function(message){

      igvshiny_log("=== loadVcfTrack");
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var vcfFile = message.vcfDataFilepath;
      var dataURL = window.location.href + message.vcfDataFilepath;
      igvshiny_log("dataURL: " + dataURL);

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
      igvshiny_log("dataURL: " + dataURL);

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
// either local url (pointing to a just-written data.frame) or a remote url
Shiny.addCustomMessageHandler("loadGwasTrackFlexibleSource",

   function(message){

      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var dataMode = message.dataMode;
      var trackName = message.trackName;
      var url = message.dataUrl;
      var trackHeight = message.trackHeight;
      var autoscale = message.autoscale;
      var min = message.min;
      var max = message.max;

      if(dataMode == "local.ulr")
          url = window.location.href + url;

      igvshiny_log("url: " + url)

      var config = {format: "gwas",
                    type: "gwas",
                    name: trackName,
                    order: Number.MAX_VALUE,
		    url: url,
                    indexed: false,
                    displayMode: "EXPANDED",
                    height: trackHeight,
                    autoscale: autoscale,
                    min: min,
                    max: max
                    };
      igvBrowser.loadTrack(config);
      }

); // loadGwasTrackFlexibleSource
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBamTrackFromURL",

   function(message){
      igvshiny_log("=== loadBamTrack");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var bamFile = message.bam;
      var baiFile = message.index;
      var displayMode = message.displayMode;
      var showAllBases = message.showAllBases;

      var config = {format: "bam",
                    name: trackName,
                    displayMode: displayMode,
                    showAllBases: showAllBases,
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
      igvshiny_log("=== loadBamTrackFromLocalData");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var dataURL = window.location.href + message.bamDataFilepath;
      var trackName = message.trackName;
      var displayMode = message.displayMode;

      var config = {format: "bam",
                    name: trackName,
                    displayMode: displayMode,
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
      igvshiny_log("=== loadCramTrackFromURL");
      igvshiny_log(message)
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
Shiny.addCustomMessageHandler("loadGFF3TrackFromURL",

   function(message){
      igvshiny_log("=== loadGFF3TrackFromURL");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;

      var indexedData = message.indexURL.length > 0;
       
       var config = {type: "annotation",
                     format: "gff3",
                     name: message.name,
                     url: message.dataURL,
                     indexURL: message.indexURL,
                     indexed: indexedData,
                     displayMode: message.displayMode,
                     visibilityWindow: message.visibilityWindow,
                     order: Number.MAX_VALUE,
                     height: message.trackHeight};
       
      if(Object.keys(message.colorTable).length > 0 && message.colorByAttribute.length > 0){
         config.colorTable = message.colorTable;
         config.colorBy = message.colorByAttribute;
         }
      else{
         config.color=message.color;
         }
       
       igvBrowser.loadTrack(config)
       igvshiny_log("=== after loadTrack, loadGFF3TrackFromURL")
     } // function

); // loadGFF3TrackFromURL
//----------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadGFF3TrackFromLocalData",

   function(message){
      igvshiny_log("=== loadGFF3TrackFromLocalData");
      igvshiny_log(message)

      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var dataURL = window.location.href + message.filePath;

       var config = {type: "annotation",
                     format: "gff3",
                    //nameField: "gene",
                    name: message.trackName,
                    url: dataURL,
                    indexed: false,
                    displayMode: message.displayMode,
                    visibilityWindow: message.visibilityWindow,
                    order: Number.MAX_VALUE,
                    height: message.trackHeight};
       
      if(Object.keys(message.colorTable).length > 0 && message.colorByAttribute.length > 0){
         config.colorTable = message.colorTable;
         config.colorBy = message.colorByAttribute;
         }
      else{
         config.color=message.color;
         }

       igvBrowser.loadTrack(config)
      } // function

);  // loadGFF3TrackFromLocalData
//------------------------------------------------------------------------------------------------------------------------

