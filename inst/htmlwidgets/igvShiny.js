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

//----------------------------------------------------------------------------------------------------
// Generic helper function to merge extra parameters from R into the config object
function mergeExtraParameters(config, message) {
    var handledKeys = Object.keys(config);
    handledKeys.push("elementID", "tbl", "trackName"); // also ignore these top-level message keys

    for (var key in message) {
        if (message.hasOwnProperty(key) && !handledKeys.includes(key)) {
            config[key] = message[key];
        }
    }
    return config;
}
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
         var igvDiv_jquerySignature = "#" + igvDiv.id;
         $(igvDiv_jquerySignature).children().remove() // any previously created igv instance
         igvshiny_log("---- el");
         igvshiny_log(el);
         igvshiny_log(el.id)
         var htmlContainerID = el.id;
         // the custom message handlers below live outside this factory and never
         // see `options`, so park the namespace on the element itself (#134)
         el.moduleNS = options.moduleNS || "";
         igvshiny_log("fasta: " + options.fasta)
         igvshiny_log("index: " + options.fastaIndex)
         var fullOptions = genomeSpecificOptions(options.genomeName,
                                                 options.stockGenome,
                                                 options.dataMode,
                                                 options.initialLocus,
                                                 options.displayMode,
                                                 parseInt(options.trackHeight),
                                                 options.fasta,
                                                 options.fastaIndex,
                                                 options.annotation,
                                                 options.moduleNS,
                                                 options.tracks)

         igvshiny_log("about to createBrowser, trackHeight: " + fullOptions.height)
         igv.createBrowser(igvDiv, fullOptions)
             .then(function (browser) {
                igvshiny_log("createBrowser promise fulfilled");
                igvWidget = browser;
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
                igvWidget.on('locuschange', debounce(function (referenceFrameList){
                   igvshiny_log("---- locuschange, referenceFrameList: ")
                   igvshiny_log(referenceFrameList);
                   // igv.js 3.x fires locuschange with the referenceFrameList; read the
                   // first frame and rebuild the comma-free "chr:start-end" string that
                   // currentGenomicRegion has always emitted, guarding the whole-genome
                   // "all" view (raw start/end are meaningless there).
                   //
                   // The frame start is 0-based internally, while browser.search() reads
                   // its input as 1-based and subtracts one. Emitting the raw value cost
                   // a base per round trip, so an app that reported a region and later
                   // sent it back crept left one step at a time (#126).
                   var refFrame = referenceFrameList[0];
                   var chromLocString = (refFrame.chr === "all")
                      ? "all"
                      : refFrame.chr + ":" + (Math.floor(refFrame.start) + 1) + "-" + Math.round(refFrame.end);
                   
                   // Compare against this widget's own last locus, not a global:
                   // two widgets sitting at the same locus would otherwise
                   // suppress each other's currentGenomicRegion event (#126).
                   var container = document.getElementById(htmlContainerID);
                   var previousLocString = container.chromLocString;
                   container.chromLocString = chromLocString;
                   var eventNames = currentGenomicRegionEventNames(htmlContainerID);
                   var eventName = eventNames.plain;
                   igvshiny_log("--- calling Shiny.setInputValue:");
   		   igvshiny_log("eventName: " + eventName);
                   igvshiny_log("chromLocString:          " + chromLocString);
                   igvshiny_log("previous chromLocString: " + previousLocString);
                   var newRegion = chromLocString != previousLocString;
                   igvshiny_log("--- new.loc? " + newRegion);
                   if(newRegion){
                      igvshiny_log("--- generating currentGenomicRegion event: " + chromLocString)
                      Shiny.setInputValue(eventName, chromLocString, {priority: "event"});
                      var moduleEventName = eventNames.scoped;
                      if(moduleEventName != eventName){
                         igvshiny_log("moduleEventName: " + moduleEventName);
                         Shiny.setInputValue(moduleEventName, chromLocString, {priority: "event"});
                         }
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
// the region is announced from two places - the locuschange listener and the
// getGenomicRegion handler - and they used to build the module-scoped name
// differently, so a module named anything but "igv" never received the reply
// (#134). Build both names here so the two paths cannot drift again.
function currentGenomicRegionEventNames(elementID)
{
  var el = document.getElementById(elementID);
  var ns = (el && el.moduleNS) ? el.moduleNS : "";
  return {
     plain: "currentGenomicRegion." + elementID,
     scoped: moduleNamespace(ns, "currentGenomicRegion.") + elementID.replace(ns, "")
     }
}
//------------------------------------------------------------------------------------------------------------
// A stock genome is normally requested by bare id and igv.js resolves it
// against https://igv.org/genomes/genomes3.json. For the human genomes every
// asset that registry names - sequence, cytobands and the RefSeq annotation
// alike - sits on hgdownload.soe.ucsc.edu, and the browser draws nothing until
// they arrive. Two things go wrong there:
//
//   - the RefSeq track it ships is whole-genome and unindexed, so igv.js pulls
//     ~25 MB down before the first gene appears, however small the locus;
//   - hgdownload throttles hard. Measured 2026-08-06: 35 s for a 1 kB range
//     request and 60 s timeouts, while the same bytes came off igv.org in 0.5 s.
//
// Together that is a browser which looks hung for half a minute on startup,
// reported against the public demo. The URLs below carry the same data from
// igv.org and the igv.org.genomes bucket, and the annotation is the
// tabix-indexed build, so startup reads a few kB covering the visible locus
// instead of the whole genome.
//
// mm10 stays on the registry id on purpose: the bucket has its indexed RefSeq
// but no cytoband file, and losing the ideogram to gain startup time is the
// worse trade.
function pinnedReference(genomeName)
{
  var chromosomeOrder =
      "chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12," +
      "chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY";

  var refseqTrack = function(stem){
     return {
        name: "Refseq Genes",
        format: "refgene",
        url: stem + ".sorted.txt.gz",
        indexURL: stem + ".sorted.txt.gz.tbi",
        indexed: true,
        removable: false,
        order: 1000000,
        infoURL: "https://www.ncbi.nlm.nih.gov/gene/?term=$$"
        };
     };

  var references = {
     hg19: {
        id: "hg19",
        name: "Human (GRCh37/hg19)",
        twoBitURL: "https://igv.org/genomes/data/hg19/hg19.2bit",
        chromSizesURL: "https://igv.org/genomes/data/hg19/hg19.chrom.sizes",
        cytobandURL: "https://igv.org/genomes/data/hg19/cytoBand.txt.gz",
        aliasURL: "https://s3.amazonaws.com/igv.org.genomes/hg19/hg19_alias.tab",
        chromosomeOrder: chromosomeOrder,
        tracks: [refseqTrack("https://s3.amazonaws.com/igv.org.genomes/hg19/ncbiRefSeq")]
        },
     hg38: {
        id: "hg38",
        name: "Human (GRCh38/hg38)",
        twoBitURL: "https://igv.org/genomes/data/hg38/hg38.2bit",
        chromSizesURL: "https://igv.org/genomes/data/hg38/hg38.chrom.sizes",
        cytobandURL: "https://igv.org/genomes/data/hg38/cytoBandIdeo.txt.gz",
        aliasURL: "https://s3.amazonaws.com/igv.org.genomes/hg38/hg38_alias.tab",
        chromosomeOrder: chromosomeOrder,
        tracks: [refseqTrack("https://s3.amazonaws.com/igv.org.genomes/hg38/ncbiRefSeq")]
        }
     };

  return references.hasOwnProperty(genomeName) ? references[genomeName] : null;
}
//------------------------------------------------------------------------------------------------------------
function genomeSpecificOptions(genomeName, stockGenome, dataMode, initialLocus, displayMode, trackHeight,
                               fasta, fastaIndex, annotation, moduleNS, tracks)
{
    if(stockGenome){
       igvOptions = {
         locus: initialLocus,
         height: trackHeight,
         minimumBases: 5,
         flanking: 1000,
	       name: genomeName,
         showRuler: true
         };
       // Stock genomes are requested by bare id: igv.js 3.x looks the id up in
       // https://igv.org/genomes/genomes3.json, which carries a working twoBit
       // sequence for every genome igvShiny offers (issue #107). The human
       // genomes are the exception - see pinnedReference above.
       var pinned = pinnedReference(genomeName);
       if(pinned){
          igvOptions.reference = pinned;
       } else {
          igvOptions.genome = genomeName;
       }
       if (tracks && tracks.length > 0) {
          igvOptions.tracks = tracks;
       }
       return(igvOptions)
       }

    // everything below this point is reached only for a custom genome: a stock
    // one has already returned above

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
    
    // The Gencode v18 track this used to carry came from the
    // igv.broadinstitute.org s3 bucket, which now answers 403. The registry
    // entry for hg19 ships a RefSeq All track, so the annotation comes with the
    // bare id and there is nothing left for us to pin (issue #143)
    var hg19_options = {
        locus: initialLocus,
        flanking: 1000,
        showRuler: true,
        minimumBases: 5,
        genome: "hg19"
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
    
    // tair10 is in the igv.js registry, sequence and RefSeq annotation included,
    // so the bare id replaces the fasta we used to host ourselves - it has been
    // answering 404 since the igvr paths were cleared (issue #143). The registry
    // entry carries an aliasURL, so data named chr1 or 1 still resolves; what
    // changes is the displayed name, the RefSeq accession (NC_003070.9 ...).
    // The annotation now comes from the registry as "RefSeq All" rather than the
    // "Genes TAIR10" track this config used to carry, so code addressing it by
    // the old name - removeTracksByName above all - no longer matches anything
    var tair10_options = {
        locus: initialLocus,
        flanking: 2000,
	      showKaryo: false,
        showNavigation: true,
        minimumBases: 5,
        showRuler: true,
        genome: "tair10"
    }; // tair10_options

    // rhos is in no igv.js registry, but UCSC publishes the same assembly as an
    // assembly hub, so the sequence and the genes come from there instead of
    // from us. GCF_000012905.2 is ASM1290v2, the accession the old self-hosted
    // filenames already carried (issue #143)
    var rhos_hub = "https://hgdownload.soe.ucsc.edu/hubs/GCF/000/012/905/GCF_000012905.2";
    var rhos_options = {
        locus: initialLocus,
        flanking: 2000,
	showKaryo: false,
        showNavigation: true,
        minimumBases: 5,
        showRuler: true,
        reference: {id: "GCF_000012905.2",
                    name: "R. sphaeroides 2.4.1 (ASM1290v2)",
                    twoBitURL: rhos_hub + "/GCF_000012905.2.2bit",
                    aliasURL: rhos_hub + "/GCF_000012905.2.chromAlias.txt",
                    chromSizesURL: rhos_hub + "/GCF_000012905.2.chrom.sizes.txt"
                   },
        tracks: [
            {name: 'Genes',
             format: 'bigbed',
             visibilityWindow: 500000,
             url: rhos_hub + "/bbi/GCF_000012905.2_ASM1290v2.ncbiGene.bb",
             color: "darkred",
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

    if (igvOptions && tracks && tracks.length > 0) {
        igvOptions.tracks = tracks;
    }
    return(igvOptions)

} // genomeSpecificOptions
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
       var eventNames = currentGenomicRegionEventNames(elementID);
       igvshiny_log("--- calling Shiny.setInputValue:");
       igvshiny_log("eventName: " + eventNames.plain);
       igvshiny_log("chromLocString: " + currentValue)
       Shiny.setInputValue(eventNames.plain, currentValue, {priority: "event"});
       if(eventNames.scoped != eventNames.plain){
          igvshiny_log("moduleEventName: " + eventNames.scoped);
          Shiny.setInputValue(eventNames.scoped, currentValue, {priority: "event"});
          }
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
      config = mergeExtraParameters(config, message);
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
      config = mergeExtraParameters(config, message);
      igvBrowser.loadTrack(config);
      }


);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedTrackFromFile",

   function(message){
      igvshiny_log("=== loadBedTrackFromFile");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var bedFile = message.bedFilepath;
      var dataURL = window.location.href.split('?')[0] + bedFile; // If a query string is present the url before that is used
      igvshiny_log("dataURL: " + dataURL);

      var color = message.color;
      var trackHeight = message.trackHeight;

      var config = {format: "bed",
                    name: trackName,
                    type: "annotation",
                    order: Number.MAX_VALUE,
                    url: dataURL,
                    indexed: false,
                    displayMode: "EXPANDED",
                    color: color,
                    height: trackHeight
                    };
      config = mergeExtraParameters(config, message);
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
      config = mergeExtraParameters(config, message);
      if(autoscaleGroup !== -1 && autoscaleGroup !== undefined && autoscaleGroup !== null)
          config['autoscaleGroup'] = autoscaleGroup;
      console.log("--- loading bedGraphTrack");
      console.log(config)
      igvBrowser.loadTrack(config);
      }

);
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadBedGraphTrackFromURL",

   function(message){
      igvshiny_log("=== loadBedGraphTrackFromURL");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;
      var trackName = message.trackName;
      var color = message.color;
      var trackHeight = message.trackHeight;
      var autoscale = message.autoscale;
      var autoscaleGroup = message.autoscaleGroup;
      var min = message.min;
      var max = message.max;
      var url = message.url;       

      var config = {type: "wig",
                    name: trackName,
                    url: url,
                    order: Number.MAX_VALUE,
                    color: color,
                    autoscale: autoscale,
                    min: min,
                    max: max
                    //height: trackHeight
                    };

     // type: "wig",
     // name: "CTCF",
     // url: "https://www.encodeproject.org/files/ENCFF356YES/@@download/ENCFF356YES.bigWig",
     // min: "0",
     // max: "30",
     // color: "rgb(0, 0, 150)",


      console.log("--- loading bedGraphTrackFromURL");
      console.log(config)
      config = mergeExtraParameters(config, message);
      if(autoscaleGroup !== -1 && autoscaleGroup !== undefined && autoscaleGroup !== null)
          config['autoscaleGroup'] = autoscaleGroup;
      igvBrowser.loadTrack(config);
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
      config = mergeExtraParameters(config, message);
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


       config = mergeExtraParameters(config, message);
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
      config = mergeExtraParameters(config, message);
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

      if(dataMode == "local.url")
          url = window.location.href + url;

      igvshiny_log("loadGwasTrackFlexibleSource, url: " + url)

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
      config = mergeExtraParameters(config, message);
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
      config = mergeExtraParameters(config, message);
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
      config = mergeExtraParameters(config, message);
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
      config = mergeExtraParameters(config, message);
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
                     name: message.trackName,
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
       
       config = mergeExtraParameters(config, message);
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

       config = mergeExtraParameters(config, message);
       igvBrowser.loadTrack(config)
      } // function

);  // loadGFF3TrackFromLocalData
//------------------------------------------------------------------------------------------------------------------------
Shiny.addCustomMessageHandler("loadSpliceJunctionTrackFromURL",

   function(message){
      igvshiny_log("=== loadSpliceJunctionTrackFromURL");
      igvshiny_log(message)
      var elementID = message.elementID;
      var igvBrowser = document.getElementById(elementID).igvBrowser;

      // "junction" is the registered type; "junctions" and "spliceJunctions"
      // are aliases igv.js normalizes onto it. An unindexed bed has to say so
      // through "indexed": on an empty indexURL igv.js otherwise guesses
      // url + ".tbi" and fails on a file that is not there
      var indexedData = message.indexURL.length > 0;

      var config = {type: "junction",
                    format: "bed",
                    name: message.trackName,
                    url: message.url,
                    indexURL: message.indexURL,
                    indexed: indexedData,
                    displayMode: message.displayMode,
                    order: Number.MAX_VALUE,
                    height: message.trackHeight};

      config = mergeExtraParameters(config, message);
      igvBrowser.loadTrack(config);
      igvshiny_log("=== after loadTrack, loadSpliceJunctionTrackFromURL")
      } // function

);  // loadSpliceJunctionTrackFromURL
//------------------------------------------------------------------------------------------------------------------------

