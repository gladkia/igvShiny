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
          igvWidget = igv.createBrowser(igvDiv, fullOptions);

           Shiny.addCustomMessageHandler("showGenomicRegion", function(message) {
               //window.igvBrowser.search(message.roi);
              igvWidget.search(message.roi)
              });

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
                     fastaURL: "http://trena.systemsbiology.net/mm10/GRCm38.primary_assembly.genome.fa",
                     cytobandURL: "http://trena.systemsbiology.net/mm10/cytoBand.txt"
                     },
         tracks: [
            {name: 'Gencode vM14',
             url: "http://trena.systemsbiology.net/mm10/gencode.vM14.basic.annotation.sorted.gtf.gz",
             indexURL: "http://trena.systemsbiology.net/mm10/gencode.vM14.basic.annotation.sorted.gtf.gz.tbi",
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
                fastaURL: "http://trena.systemsbiology.net/tair10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa",
                indexURL: "http://trena.systemsbiology.net/tair10/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.fai",
                aliasURL: "http://trena.systemsbiology.net/tair10/chromosomeAliases.txt"
                },
         tracks: [
           {name: 'Genes TAIR10',
            type: 'annotation',
            visibilityWindow: 500000,
            url: "http://trena.systemsbiology.net/tair10/TAIR10_genes.sorted.chrLowered.gff3.gz",
            color: "darkred",
            indexed: true,
            height: 200,
            displayMode: "EXPANDED"
            },
            ]
          }; // tair10_options

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
         } // switch on genomeName

    return(igvOptions)

} // genomeSpecificOptions
//------------------------------------------------------------------------------------------------------------------------




