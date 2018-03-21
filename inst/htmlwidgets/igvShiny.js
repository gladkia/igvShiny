HTMLWidgets.widget({

  name: 'igvShiny',

  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
        el.innerText = x.message;
          console.log("----- el")
          console.log(el)
          el.append($("<h3> added h3</h3>"))
          },

      resize: function(width, height) {
        // TODO: code to re-render the widget with a new size
        }

    };
  }
});  // widget

/*********************************
function initializeIGV(self, genomeName)
{
   console.log("--- trenaViz, initializeIGV");

   checkSignature(self, "initializeIGV")

    var hg19_options = {
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
	//locus: "MEF2C",
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
           {name: 'bud DHS',
             type: 'wig',
             url: "http://trena.systemsbiology.net/tair10/frd3.bw",
             height: 100
             },
           {name: 'leaf DHS',
             type: 'wig',
             url: "http://trena.systemsbiology.net/tair10/frd3-leaf.bw",
             height: 100
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
         } // switch on genoneName

   $("#igvDiv").children().remove()

   console.log("--- trenaViz, igv:");
   console.log(igv)
   console.log("about to createBrowser");

   var igvBrowser = igv.createBrowser($("#igvDiv"), igvOptions);

   igvBrowser.on("locuschange",
       function(referenceFrame, chromLocString){
         self.chromLocString = chromLocString;
         });

   return(igvBrowser);

} // initializeIGV
//----------------------------------------------------------------------------------------------------
****************/
