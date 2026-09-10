#-------------------------------------------------------------------------------
# Canonical chromosome sizes for common standard reference genomes.
# Provides instant, offline, zero-network verification of contig lengths.
#-------------------------------------------------------------------------------
.canonicalChromSizes <- list(
  hg38 = c(
    chr1 = 248956422L, chr2 = 242193529L, chr3 = 198295559L, chr4 = 190214555L,
    chr5 = 181538259L, chr6 = 170805979L, chr7 = 159345973L, chr8 = 145138636L,
    chr9 = 138394717L, chr10 = 133797422L, chr11 = 135086622L, chr12 = 133275309L,
    chr13 = 114364328L, chr14 = 107043718L, chr15 = 101991189L, chr16 = 90338345L,
    chr17 = 83257441L, chr18 = 80373285L, chr19 = 58617616L, chr20 = 64444167L,
    chr21 = 46709983L, chr22 = 50818468L, chrX = 156040895L, chrY = 57227415L,
    chrM = 16569L
  ),
  hg19 = c(
    chr1 = 249250621L, chr2 = 243199373L, chr3 = 198022430L, chr4 = 191154276L,
    chr5 = 180915260L, chr6 = 171115067L, chr7 = 159138663L, chr8 = 146364022L,
    chr9 = 141213431L, chr10 = 135534747L, chr11 = 135006516L, chr12 = 133851895L,
    chr13 = 115169878L, chr14 = 107349540L, chr15 = 102531392L, chr16 = 90354753L,
    chr17 = 81195210L, chr18 = 78077248L, chr19 = 59128983L, chr20 = 63025520L,
    chr21 = 48129895L, chr22 = 51304566L, chrX = 155270560L, chrY = 59373566L,
    chrM = 16571L
  ),
  mm10 = c(
    chr1 = 195471971L, chr2 = 182113224L, chr3 = 160039680L, chr4 = 156508116L,
    chr5 = 151834684L, chr6 = 149736546L, chr7 = 145441459L, chr8 = 129401213L,
    chr9 = 124595110L, chr10 = 130694993L, chr11 = 122082543L, chr12 = 120129022L,
    chr13 = 120421639L, chr14 = 124902244L, chr15 = 104043685L, chr16 = 98207768L,
    chr17 = 94987271L, chr18 = 90702639L, chr19 = 61431566L, chrX = 171031299L,
    chrY = 91744698L, chrM = 16299L
  ),
  mm39 = c(
    chr1 = 195154279L, chr2 = 181755017L, chr3 = 159745316L, chr4 = 156860686L,
    chr5 = 151758149L, chr6 = 149588044L, chr7 = 144998471L, chr8 = 130127059L,
    chr9 = 124359700L, chr10 = 130530862L, chr11 = 121973369L, chr12 = 120092757L,
    chr13 = 120883175L, chr14 = 125139656L, chr15 = 104073951L, chr16 = 98008968L,
    chr17 = 95294699L, chr18 = 90720763L, chr19 = 61420004L, chrX = 169476592L,
    chrY = 91455390L, chrM = 16299L
  ),
  dm6 = c(
    chr2L = 23513712L, chr2R = 25286936L, chr3L = 28110227L, chr3R = 32079331L,
    chr4 = 1348131L, chrX = 23542271L, chrY = 3667352L, chrM = 19524L
  ),
  sacCer3 = c(
    chrI = 230218L, chrII = 813184L, chrIII = 316620L, chrIV = 1531933L,
    chrV = 576874L, chrVI = 270161L, chrVII = 1090940L, chrVIII = 562643L,
    chrIX = 439888L, chrX = 745751L, chrXI = 666816L, chrXII = 1078177L,
    chrXIII = 924431L, chrXIV = 784333L, chrXV = 1091291L, chrXVI = 948066L,
    chrM = 85779L
  ),
  tair10 = c(
    Chr1 = 30427671L, Chr2 = 19698289L, Chr3 = 23459830L, Chr4 = 18585056L,
    Chr5 = 26975502L, ChrM = 366924L, ChrC = 154478L
  )
)

# Reference genome aliases mapping to standard identifiers
.genomeAliases <- c(
  "grch38" = "hg38",
  "grch38.p13" = "hg38",
  "grch38.p14" = "hg38",
  "grch37" = "hg19",
  "b37" = "hg19",
  "hs37d5" = "hg19",
  "grcm38" = "mm10",
  "grcm39" = "mm39",
  "dmel6" = "dm6",
  "saccer" = "sacCer3",
  "arabidopsis" = "tair10"
)

# Normalize genome name to canonical key
.canonicalGenomeName <- function(genomeName) {
  if (is.null(genomeName) || !is.character(genomeName) || length(genomeName) != 1L ||
      is.na(genomeName) || !nzchar(genomeName)) {
    return(NULL)
  }
  lower <- tolower(trimws(genomeName))
  if (lower %in% names(.canonicalChromSizes)) {
    return(lower)
  }
  if (lower %in% names(.genomeAliases)) {
    return(.genomeAliases[[lower]])
  }
  # Handle embedded strings or URLs e.g. ftp://.../hs37d5.fa.gz
  for (alias in names(.genomeAliases)) {
    if (grepl(paste0("(^|[^a-z0-9])", alias, "([^a-z0-9]|$)"), lower)) {
      return(.genomeAliases[[alias]])
    }
  }
  for (canon in names(.canonicalChromSizes)) {
    if (grepl(paste0("(^|[^a-z0-9])", canon, "([^a-z0-9]|$)"), lower)) {
      return(canon)
    }
  }
  return(genomeName)
}

#-------------------------------------------------------------------------------
# Session Genome Spec Management
#-------------------------------------------------------------------------------

#' Register active genome spec for an igvShiny widget instance
#' @param session Shiny session or NULL
#' @param elementId Character string or NULL
#' @param genomeOptions Named list of genome options
#' @keywords internal
.registerGenomeSpec <- function(session, elementId, genomeOptions) {
  # Record in package state environment as global fallback
  state[["lastGenomeSpec"]] <- genomeOptions

  if (is.null(session)) {
    return(invisible(NULL))
  }

  # Assignment goes through local binding to userData environment to avoid proxy issues
  user_data <- session$userData
  if (is.null(user_data)) {
    return(invisible(NULL))
  }

  registry <- user_data$igvShinyGenomeSpecs
  if (is.null(registry)) {
    registry <- new.env(parent = emptyenv())
    user_data$igvShinyGenomeSpecs <- registry
  }

  # elementId is NULL in every demo; inside renderIgvShiny() shiny knows the
  # output id, which is exactly the id the track loaders are called with
  if (is.null(elementId) || !nzchar(elementId)) {
    elementId <- tryCatch(shiny::getCurrentOutputInfo()[["name"]],
                          error = function(e) NULL)
  }

  if (!is.null(elementId) && is.character(elementId) && nzchar(elementId)) {
    registry[[elementId]] <- genomeOptions
  }

  previous <- registry[[".last"]]
  if (!is.null(previous) && !identical(previous, genomeOptions)) {
    registry[[".ambiguous"]] <- TRUE
  }
  registry[[".last"]] <- genomeOptions
  invisible(NULL)
}

#' Retrieve active genome spec for an igvShiny widget instance
#' @param session Shiny session or NULL
#' @param id Character string, the widget element id
#' @return Named list of genome options, or NULL
#' @keywords internal
.getGenomeSpec <- function(session, id = NULL) {
  if (!is.null(session)) {
    user_data <- session$userData
    if (!is.null(user_data) && !is.null(user_data$igvShinyGenomeSpecs)) {
      registry <- user_data$igvShinyGenomeSpecs
      if (!is.null(id) && !is.null(registry[[id]])) {
        return(registry[[id]])
      }
      # no entry under this id: validating against another widget's genome
      # invents mismatches, so fall back to the last spec only while every
      # widget in this session agrees on one
      if (isTRUE(registry[[".ambiguous"]])) {
        return(NULL)
      }
      if (!is.null(registry[[".last"]])) {
        return(registry[[".last"]])
      }
    }
    return(NULL)
  }

  if ("lastGenomeSpec" %in% ls(state)) {
    return(state[["lastGenomeSpec"]])
  }
  NULL
}

#-------------------------------------------------------------------------------
# Reference Contig Extractor
#-------------------------------------------------------------------------------

#' Extract contig names and lengths from genome options
#' @param genomeSpec Named list of genome options, or character string (genome name)
#' @return Named integer vector of contig lengths, or NULL
#' @keywords internal
.getReferenceContigs <- function(genomeSpec) {
  if (is.character(genomeSpec) && length(genomeSpec) == 1L) {
    canon <- .canonicalGenomeName(genomeSpec)
    if (!is.null(canon) && canon %in% names(.canonicalChromSizes)) {
      return(.canonicalChromSizes[[canon]])
    }
    return(NULL)
  }

  if (!is.list(genomeSpec)) {
    return(NULL)
  }

  # If custom genome with fastaIndex (.fai)
  if (isFALSE(genomeSpec[["stockGenome"]]) &&
      !is.null(genomeSpec[["fastaIndex"]]) &&
      !is.na(genomeSpec[["fastaIndex"]]) &&
      file.exists(genomeSpec[["fastaIndex"]])) {
    tryCatch({
      tbl <- utils::read.table(
        genomeSpec[["fastaIndex"]],
        header = FALSE,
        sep = "\t",
        stringsAsFactors = FALSE,
        comment.char = "",
        quote = ""
      )
      lengths <- as.integer(tbl[[2]])
      names(lengths) <- as.character(tbl[[1]])
      return(lengths)
    }, error = function(e) NULL)
  }

  # Stock genome
  name <- genomeSpec[["genomeName"]]
  canon <- .canonicalGenomeName(name)
  if (!is.null(canon) && canon %in% names(.canonicalChromSizes)) {
    return(.canonicalChromSizes[[canon]])
  }

  NULL
}

#-------------------------------------------------------------------------------
# Track Contig Extractors
#-------------------------------------------------------------------------------

# Extract tag from formatted lines e.g. SN:chr1 or LN:1000
.extractTag <- function(line, tag) {
  m <- regexec(paste0("(?:^|[[:space:]])", tag, ":([^[:space:]]+)"), line)
  matches <- regmatches(line, m)[[1]]
  if (length(matches) >= 2L) matches[2] else NULL
}

# Extract key=val from header lines e.g. ID=chr1 or length=1000
.extractKeyVal <- function(line, key) {
  m <- regexec(paste0("(?:[<,]|^)", key, "=([^,>]+)"), line)
  matches <- regmatches(line, m)[[1]]
  if (length(matches) >= 2L) matches[2] else NULL
}

#' Extract contig information from a BAM file
#' @param bamFile Path to a readable .bam file
#' @return List with contigs (named integer vector) and assembly (string or NULL)
#' @keywords internal
.extractBamContigs <- function(bamFile) {
  # 1. Try Rsamtools if available
  if (requireNamespace("Rsamtools", quietly = TRUE)) {
    res <- tryCatch({
      hdr <- Rsamtools::scanBamHeader(bamFile)[[1]]
      targets <- as.integer(hdr$targets)
      names(targets) <- names(hdr$targets)
      assembly <- NULL
      if (!is.null(hdr$text)) {
        sq_lines <- hdr$text[names(hdr$text) == "@SQ"]
        for (sq in sq_lines) {
          assembly <- .extractTag(paste(sq, collapse = "\t"), "AS")
          if (!is.null(assembly)) {
            break
          }
        }
      }
      list(contigs = targets, assembly = assembly)
    }, error = function(e) NULL)
    if (!is.null(res) && length(res$contigs) > 0L) {
      return(res)
    }
  }

  # 2. Native base R BGZF header parser fallback
  tryCatch({
    con <- gzcon(file(bamFile, "rb"))
    on.exit(close(con), add = TRUE)
    magic <- readBin(con, "raw", 4L)
    if (!identical(rawToChar(magic), "BAM\1")) {
      return(NULL)
    }
    l_text <- readBin(con, "integer", 1L, endian = "little")
    if (length(l_text) == 0L || l_text <= 0L || l_text > 50000000L) {
      return(NULL)
    }
    raw_header <- readBin(con, "raw", l_text)
    header_text <- rawToChar(raw_header)

    lines <- strsplit(header_text, "\n")[[1]]
    sq_lines <- grep("^@SQ", lines, value = TRUE)
    if (length(sq_lines) == 0L) {
      return(NULL)
    }

    names <- character(length(sq_lines))
    lengths <- integer(length(sq_lines))
    assembly <- NULL

    for (i in seq_along(sq_lines)) {
      line <- sq_lines[i]
      sn <- .extractTag(line, "SN")
      ln <- .extractTag(line, "LN")
      names[i] <- if (!is.null(sn)) sn else paste0("contig_", i)
      lengths[i] <- if (!is.null(ln)) as.integer(ln) else NA_integer_
      if (is.null(assembly)) {
        assembly <- .extractTag(line, "AS")
      }
    }
    names(lengths) <- names
    list(contigs = lengths, assembly = assembly)
  }, error = function(e) NULL)
}

# itf8 decoder for CRAM containers
.read_itf8 <- function(con) {
  b0 <- as.integer(readBin(con, "raw", 1L))
  if (length(b0) == 0L) return(NA_integer_)
  if (bitwAnd(b0, 0x80) == 0L) {
    return(b0)
  } else if (bitwAnd(b0, 0x40) == 0L) {
    b1 <- as.integer(readBin(con, "raw", 1L))
    return(bitwOr(bitwShiftL(bitwAnd(b0, 0x3F), 8L), b1))
  } else if (bitwAnd(b0, 0x20) == 0L) {
    b <- as.integer(readBin(con, "raw", 2L))
    return(bitwOr(bitwShiftL(bitwAnd(b0, 0x1F), 16L),
                  bitwOr(bitwShiftL(b[1], 8L), b[2])))
  } else if (bitwAnd(b0, 0x10) == 0L) {
    b <- as.integer(readBin(con, "raw", 3L))
    return(bitwOr(bitwShiftL(bitwAnd(b0, 0x0F), 24L),
                  bitwOr(bitwShiftL(b[1], 16L),
                         bitwOr(bitwShiftL(b[2], 8L), b[3]))))
  } else {
    b <- as.integer(readBin(con, "raw", 4L))
    return(bitwOr(bitwShiftL(b[1], 24L),
                  bitwOr(bitwShiftL(b[2], 16L),
                         bitwOr(bitwShiftL(b[3], 8L), b[4]))))
  }
}

#' Extract contig information from a CRAM file
#' @param cramFile Path to a readable .cram file
#' @return List with contigs (named integer vector) and assembly (string or NULL)
#' @keywords internal
.extractCramContigs <- function(cramFile) {
  tryCatch({
    con <- file(cramFile, "rb")
    on.exit(close(con), add = TRUE)

    magic <- rawToChar(readBin(con, "raw", 4L))
    if (!identical(magic, "CRAM")) {
      return(NULL)
    }

    version <- as.integer(readBin(con, "raw", 2L))
    # 20 bytes file id
    readBin(con, "raw", 20L)

    # First container header
    readBin(con, "integer", 1L, endian = "little") # container length
    .read_itf8(con) # ref_id
    .read_itf8(con) # starting_pos
    .read_itf8(con) # alignment_span
    .read_itf8(con) # num_records
    .read_itf8(con) # record_counter
    .read_itf8(con) # num_bases
    .read_itf8(con) # num_blocks
    nlandmarks <- .read_itf8(con)
    if (!is.na(nlandmarks) && nlandmarks > 0L) {
      for (i in seq_len(nlandmarks)) .read_itf8(con)
    }
    if (version[1] >= 3L) {
      readBin(con, "raw", 4L) # crc32
    }

    # Block 0: SAM header block
    method <- as.integer(readBin(con, "raw", 1L))
    readBin(con, "raw", 1L) # content_type
    .read_itf8(con)         # content_type_id
    comp_size <- .read_itf8(con)
    .read_itf8(con)         # raw_size

    if (is.na(comp_size) || comp_size <= 0L || comp_size > 50000000L) {
      return(NULL)
    }

    raw_payload <- readBin(con, "raw", comp_size)
    decompressed <- if (method == 0L) {
      raw_payload
    } else if (method == 1L) {
      memDecompress(raw_payload, type = "gzip")
    } else {
      return(NULL)
    }

    # First 4 bytes in block data is length of header text
    if (length(decompressed) < 5L) {
      return(NULL)
    }
    header_text <- rawToChar(decompressed[5L:length(decompressed)])

    lines <- strsplit(header_text, "\n")[[1]]
    sq_lines <- grep("^@SQ", lines, value = TRUE)
    if (length(sq_lines) == 0L) {
      return(NULL)
    }

    names <- character(length(sq_lines))
    lengths <- integer(length(sq_lines))
    assembly <- NULL

    for (i in seq_along(sq_lines)) {
      line <- sq_lines[i]
      sn <- .extractTag(line, "SN")
      ln <- .extractTag(line, "LN")
      names[i] <- if (!is.null(sn)) sn else paste0("contig_", i)
      lengths[i] <- if (!is.null(ln)) as.integer(ln) else NA_integer_
      if (is.null(assembly)) {
        assembly <- .extractTag(line, "AS")
      }
    }
    names(lengths) <- names
    list(contigs = lengths, assembly = assembly)
  }, error = function(e) NULL)
}

# Extract seqinfo data safely from GenomeInfoDb
.getSeqinfoData <- function(x) {
  tryCatch({
    si <- GenomeInfoDb::seqinfo(x)
    lens <- GenomeInfoDb::seqlengths(si)
    asm <- unique(stats::na.omit(GenomeInfoDb::genome(si)))[1]
    list(contigs = lens, assembly = asm)
  }, error = function(e) NULL)
}

#' Extract contig information from a VCF object or file
#' @param vcfDataOrFile A VariantAnnotation VCF object, or a path to a .vcf / .vcf.gz file
#' @return List with contigs (named integer vector) and assembly (string or NULL)
#' @keywords internal
.extractVcfContigs <- function(vcfDataOrFile) {
  # 1. Bioconductor VCF object
  if (!is.character(vcfDataOrFile)) {
    res <- .getSeqinfoData(vcfDataOrFile)
    if (!is.null(res)) {
      return(res)
    }
  }

  # 2. File path
  if (is.character(vcfDataOrFile) && length(vcfDataOrFile) == 1L && file.exists(vcfDataOrFile)) {
    tryCatch({
      is_gz <- grepl("\\.gz$", vcfDataOrFile, ignore.case = TRUE)
      con <- if (is_gz) gzfile(vcfDataOrFile, "rt") else file(vcfDataOrFile, "rt")
      on.exit(close(con), add = TRUE)

      # Sample the header lines
      lines <- readLines(con, n = 500L, warn = FALSE)
      header_lines <- grep("^##", lines, value = TRUE)
      if (length(header_lines) == 0L) return(NULL)

      contig_lines <- grep("^##contig=<", header_lines, value = TRUE)
      ref_lines <- grep("^##reference=", header_lines, value = TRUE)

      assembly <- NULL
      if (length(ref_lines) > 0L) {
        assembly <- sub("^##reference=", "", ref_lines[1])
      }

      if (length(contig_lines) > 0L) {
        names <- character(length(contig_lines))
        lengths <- integer(length(contig_lines))
        for (i in seq_along(contig_lines)) {
          cl <- contig_lines[i]
          id <- .extractKeyVal(cl, "ID")
          len <- .extractKeyVal(cl, "length")
          names[i] <- if (!is.null(id)) id else paste0("contig_", i)
          lengths[i] <- if (!is.null(len)) as.integer(len) else NA_integer_
          if (is.null(assembly)) {
            assembly <- .extractKeyVal(cl, "assembly")
          }
        }
        names(lengths) <- names
        return(list(contigs = lengths, assembly = assembly))
      }

      # If no ##contig lines, try reading CHROM from first data records
      col_line <- grep("^#CHROM", lines, value = TRUE)
      if (length(col_line) > 0L) {
        data_lines <- grep("^[^#]", lines, value = TRUE)
        if (length(data_lines) > 0L) {
          chroms <- unique(vapply(strsplit(data_lines, "\t"), `[`, character(1), 1L))
          lens <- rep(NA_integer_, length(chroms))
          names(lens) <- chroms
          return(list(contigs = lens, assembly = assembly))
        }
      }
    }, error = function(e) NULL)
  }

  NULL
}

#' Extract contig and coordinate information from a BED data.frame or file
#' @param tbl A data.frame with chr/chrom, start, end columns, or file path
#' @return List with contigs (named integer vector) and maxCoords (named integer vector)
#' @keywords internal
.extractBedContigs <- function(tbl) {
  if (is.character(tbl) && length(tbl) == 1L && file.exists(tbl)) {
    tryCatch({
      tbl <- utils::read.table(tbl, sep = "\t", header = FALSE,
                               stringsAsFactors = FALSE,
                               comment.char = "", quote = "")
      colnames(tbl)[1:3] <- c("chr", "start", "end")
    }, error = function(e) return(NULL))
  }

  if (!is.data.frame(tbl)) {
    return(NULL)
  }

  chr_col <- if ("chr" %in% colnames(tbl)) {
    "chr"
  } else if ("chrom" %in% colnames(tbl)) {
    "chrom"
  } else if (NCOL(tbl) >= 1L) {
    colnames(tbl)[1]
  } else {
    return(NULL)
  }

  chroms <- unique(as.character(tbl[[chr_col]]))
  lens <- rep(NA_integer_, length(chroms))
  names(lens) <- chroms

  max_coords <- NULL
  invalid_coords <- integer(0)
  start_col <- if ("start" %in% colnames(tbl)) {
    "start"
  } else if (NCOL(tbl) >= 2L && is.numeric(tbl[[2]])) {
    colnames(tbl)[2]
  } else {
    NULL
  }
  end_col <- if ("end" %in% colnames(tbl)) {
    "end"
  } else if (NCOL(tbl) >= 3L && is.numeric(tbl[[3]])) {
    colnames(tbl)[3]
  } else {
    NULL
  }

  if (!is.null(end_col)) {
    ends <- suppressWarnings(as.numeric(tbl[[end_col]]))
    max_coords <- tapply(ends, tbl[[chr_col]], function(v) {
      v <- v[!is.na(v)]
      if (length(v) == 0L) NA_real_ else max(v)
    })
    if (!is.null(start_col)) {
      starts <- suppressWarnings(as.numeric(tbl[[start_col]]))
      invalid_coords <- which(
        (!is.na(starts) & starts < 0) |
          (!is.na(ends) & ends < 0) |
          (!is.na(starts) & !is.na(ends) & starts > ends)
      )
    }
  }

  list(contigs = lens, maxCoords = max_coords,
       invalidCoordinates = invalid_coords)
}

#' Infer the likely assembly of a set of contigs from lengths or metadata
#' @param contigs Named integer vector of contig lengths
#' @param assemblyStr Optional string from header
#' @return String describing likely assembly or NULL
#' @keywords internal
.identifyLikelyAssembly <- function(contigs, assemblyStr = NULL) {
  if (!is.null(assemblyStr) && nzchar(assemblyStr)) {
    lower_as <- tolower(assemblyStr)
    if (grepl("grch38|hg38", lower_as)) return("GRCh38/hg38")
    if (grepl("grch37|hg19|b37|hs37d5", lower_as)) return("GRCh37/hg19")
    if (grepl("grcm38|mm10", lower_as)) return("GRCm38/mm10")
    if (grepl("grcm39|mm39", lower_as)) return("GRCm39/mm39")
  }

  if (is.null(contigs) || length(contigs) == 0L) {
    return(NULL)
  }

  norm_names <- sub("^chr", "", tolower(names(contigs)))
  chr1_idx <- which(norm_names == "1")
  if (length(chr1_idx) > 0L) {
    l1 <- contigs[chr1_idx[1]]
    if (!is.na(l1)) {
      if (abs(l1 - 248956422L) < 1000L) return("GRCh38/hg38")
      if (abs(l1 - 249250621L) < 1000L) return("GRCh37/hg19")
      if (abs(l1 - 195471971L) < 1000L) return("GRCm38/mm10")
      if (abs(l1 - 195154279L) < 1000L) return("GRCm39/mm39")
    }
  }

  NULL
}

#-------------------------------------------------------------------------------
# Core Compatibility Validator
#-------------------------------------------------------------------------------

#' Check reference compatibility between track data and genome specification
#'
#' @description Compares contig naming conventions (e.g. UCSC \code{chr1} vs
#' Ensembl \code{1}), contig lengths (e.g. hg19 vs hg38), and coordinate
#' boundaries between a track (BAM, CRAM, VCF, BED, or Bioconductor object)
#' and the active reference genome.
#'
#' @rdname checkReferenceCompatibility
#' @aliases checkReferenceCompatibility
#'
#' @param target A file path (.bam, .cram, .vcf, .vcf.gz, .bed) or data object
#'   (data.frame, GenomicAlignments, VCF, GRanges)
#' @param genomeName Character string, e.g. "hg38", "hg19", "mm10"
#' @param genomeSpec Named list of genome options, as produced by
#'   \code{\link{parseAndValidateGenomeSpec}}
#' @param session Optional Shiny session object
#' @param id Optional widget element ID
#'
#' @return A list with:
#' \itemize{
#'   \item \code{checked}: logical indicating whether both inputs could be inspected
#'   \item \code{compatible}: logical indicating if no critical mismatches were
#'     found, or \code{NA} when the inputs could not be checked
#'   \item \code{mismatches}: character vector of descriptive warning messages
#'   \item \code{details}: list of specific detected anomalies (naming, length, out-of-bounds)
#'   \item \code{targetAssembly}: detected assembly of track, if recognized
#'   \item \code{referenceAssembly}: reference genome name
#' }
#'
#' @examples
#' bamFile <- system.file(package = "igvShiny", "extdata", "tumor.bam")
#' # tumor.bam is GRCh38: compatible with hg38, incompatible with hg19
#' res1 <- checkReferenceCompatibility(bamFile, genomeName = "hg38")
#' res1$compatible  # TRUE
#'
#' res2 <- checkReferenceCompatibility(bamFile, genomeName = "hg19")
#' res2$compatible  # FALSE
#'
#' @keywords utils
#' @export
checkReferenceCompatibility <- function(target,
                                        genomeName = NULL,
                                        genomeSpec = NULL,
                                        session = NULL,
                                        id = NULL) {
  if (is.null(genomeSpec) && !is.null(genomeName)) {
    genomeSpec <- list(genomeName = genomeName, stockGenome = TRUE)
  }

  if (is.null(genomeSpec)) {
    genomeSpec <- .getGenomeSpec(session, id)
  }

  ref_name <- if (is.list(genomeSpec)) genomeSpec[["genomeName"]] else genomeName
  ref_contigs <- .getReferenceContigs(genomeSpec)

  res <- list(
    checked = FALSE,
    compatible = NA,
    mismatches = character(0),
    details = list(
      namingMismatch = FALSE,
      missingContigs = character(0),
      lengthMismatches = list(),
      metadataMismatch = FALSE,
      outOfBounds = list(),
      invalidCoordinates = integer(0)
    ),
    targetAssembly = NULL,
    referenceAssembly = ref_name
  )

  # If reference contigs cannot be resolved, we cannot validate; allow quietly
  if (is.null(ref_contigs) || length(ref_contigs) == 0L) {
    return(res)
  }

  # Extract track contig information based on input type
  track_info <- NULL
  if (is.character(target) && length(target) == 1L) {
    if (grepl("\\.bam$", target, ignore.case = TRUE)) {
      track_info <- .extractBamContigs(target)
    } else if (grepl("\\.cram$", target, ignore.case = TRUE)) {
      track_info <- .extractCramContigs(target)
    } else if (grepl("\\.vcf(\\.gz)?$", target, ignore.case = TRUE)) {
      track_info <- .extractVcfContigs(target)
    } else {
      # Try BED
      track_info <- .extractBedContigs(target)
    }
  } else if (is.data.frame(target)) {
    track_info <- .extractBedContigs(target)
  } else if (inherits(target, "GAlignments") || inherits(target, "GAlignmentPairs") ||
             inherits(target, "VCF") || inherits(target, "GRanges")) {
    track_info <- .getSeqinfoData(target)
  }

  if (is.null(track_info) || (length(track_info$contigs) == 0L && length(track_info$maxCoords) == 0L)) {
    return(res)
  }
  res$checked <- TRUE
  res$compatible <- TRUE

  track_contigs <- track_info$contigs
  track_assembly <- .identifyLikelyAssembly(track_contigs, track_info$assembly)
  res$targetAssembly <- track_assembly

  # 1. Contig presence and naming style (UCSC 'chr' vs bare names)
  track_names <- if (length(track_contigs) > 0L) names(track_contigs) else names(track_info$maxCoords)
  norm_ref_names <- sub("^chr", "", tolower(names(ref_contigs)))
  norm_track <- sub("^chr", "", tolower(track_names))
  common_norm <- intersect(norm_ref_names, norm_track)
  missing_norm <- setdiff(norm_track, norm_ref_names)

  if (length(common_norm) == 0L) {
    msg <- sprintf(
      "No track contigs match reference genome '%s'.",
      ref_name
    )
    res$compatible <- FALSE
    res$mismatches <- c(res$mismatches, msg)
    res$details$missingContigs <- track_names
  } else if (!is.null(track_info$maxCoords) && length(missing_norm) > 0L) {
    missing <- track_names[norm_track %in% missing_norm]
    msg <- sprintf(
      "Track contig(s) absent from reference genome '%s': %s.",
      ref_name, paste(missing, collapse = ", ")
    )
    res$compatible <- FALSE
    res$mismatches <- c(res$mismatches, msg)
    res$details$missingContigs <- missing
  }

  prefix_mismatches <- vapply(common_norm, function(cn) {
    ref_idx <- match(cn, norm_ref_names)
    track_idx <- match(cn, norm_track)
    grepl("^chr", names(ref_contigs)[ref_idx], ignore.case = TRUE) !=
      grepl("^chr", track_names[track_idx], ignore.case = TRUE)
  }, logical(1))
  if (any(prefix_mismatches)) {
    cn <- common_norm[which(prefix_mismatches)[1]]
    msg <- sprintf(
      "Contig naming mismatch for '%s': track and reference use different 'chr' prefixes.",
      cn
    )
    res$compatible <- FALSE
    res$mismatches <- c(res$mismatches, msg)
    res$details$namingMismatch <- TRUE
  }

  # 2. Contig length comparison (assembly mismatch, e.g. hg19 vs hg38)
  if (length(track_contigs) > 0L) {
    norm_track_names <- sub("^chr", "", tolower(names(track_contigs)))

    common_norm <- intersect(norm_ref_names, norm_track_names)

    length_diffs <- list()
    for (cn in common_norm) {
      ref_idx <- which(norm_ref_names == cn)[1]
      track_idx <- which(norm_track_names == cn)[1]
      r_len <- ref_contigs[ref_idx]
      t_len <- track_contigs[track_idx]
      if (!is.na(r_len) && !is.na(t_len) && r_len > 0L && t_len > 0L) {
        if (abs(r_len - t_len) > 0L) {
          length_diffs[[names(track_contigs)[track_idx]]] <- list(
            trackContig = names(track_contigs)[track_idx],
            refContig = names(ref_contigs)[ref_idx],
            trackLength = t_len,
            refLength = r_len
          )
        }
      }
    }

    if (length(length_diffs) > 0L) {
      first_diff <- length_diffs[[1]]
      hint <- if (!is.null(track_assembly)) {
        sprintf("Track matches %s, while active browser reference is %s.", track_assembly, ref_name)
      } else {
        "This indicates a divergent genome assembly."
      }
      msg <- sprintf(
        paste(
          "Genome assembly mismatch: contig '%s' length in track (%s bp)",
          "differs from reference '%s' (%s bp). %s In igv.js, this causes",
          "false mismatch highlights or misaligned reads (see issue #168)."
        ),
        first_diff$trackContig,
        format(first_diff$trackLength, big.mark = ","),
        ref_name,
        format(first_diff$refLength, big.mark = ","),
        hint
      )
      res$compatible <- FALSE
      res$mismatches <- c(res$mismatches, msg)
      res$details$lengthMismatches <- length_diffs
    }
  }

  # 3. Metadata assembly check (if track explicitly declares e.g. AS:GRCh37 on hg38)
  if (!is.null(track_info$assembly) && !is.na(track_info$assembly) && nzchar(track_info$assembly)) {
    canon_ref <- .canonicalGenomeName(ref_name)
    canon_track <- .canonicalGenomeName(track_info$assembly)
    known <- names(.canonicalChromSizes)
    if (!is.null(canon_ref) && !is.na(canon_ref) && canon_ref %in% known &&
        !is.null(canon_track) && !is.na(canon_track) && canon_track %in% known &&
        isTRUE(canon_ref != canon_track)) {
      if (length(res$details$lengthMismatches) == 0L) {
        msg <- sprintf(
          "Track header specifies assembly '%s', which conflicts with active reference genome '%s'.",
          track_info$assembly, ref_name
        )
        res$compatible <- FALSE
        res$mismatches <- c(res$mismatches, msg)
        res$details$metadataMismatch <- TRUE
      }
    }
  }

  # 4. Invalid and out-of-bounds coordinates (for BED/BedGraph)
  if (length(track_info$invalidCoordinates) > 0L) {
    first_invalid <- track_info$invalidCoordinates[1]
    msg <- sprintf("Invalid coordinate range in track row %d.", first_invalid)
    res$compatible <- FALSE
    res$mismatches <- c(res$mismatches, msg)
    res$details$invalidCoordinates <- track_info$invalidCoordinates
  }

  if (!is.null(track_info$maxCoords) && length(track_info$maxCoords) > 0L) {
    norm_ref_names <- sub("^chr", "", tolower(names(ref_contigs)))
    norm_coord_names <- sub("^chr", "", tolower(names(track_info$maxCoords)))

    oob <- list()
    for (i in seq_along(track_info$maxCoords)) {
      cn <- norm_coord_names[i]
      ref_idx <- which(norm_ref_names == cn)
      if (length(ref_idx) > 0L) {
        r_len <- ref_contigs[ref_idx[1]]
        m_coord <- track_info$maxCoords[i]
        if (!is.na(r_len) && !is.na(m_coord) && m_coord > r_len) {
          oob[[names(track_info$maxCoords)[i]]] <- list(
            maxCoord = m_coord,
            refLength = r_len
          )
        }
      }
    }
    if (length(oob) > 0L) {
      first_oob <- oob[[1]]
      chrom_name <- names(oob)[1]
      msg <- sprintf(
        paste(
          "Coordinate out-of-bounds: track contains features on '%s' up to %s bp,",
          "exceeding reference chromosome length of %s bp."
        ),
        chrom_name,
        format(first_oob$maxCoord, big.mark = ","),
        format(first_oob$refLength, big.mark = ",")
      )
      res$compatible <- FALSE
      res$mismatches <- c(res$mismatches, msg)
      res$details$outOfBounds <- oob
    }
  }

  res
}

#-------------------------------------------------------------------------------
# Track Loader Dispatcher
#-------------------------------------------------------------------------------

#' Internal validator dispatched by track loaders
#' @param session Shiny session or NULL
#' @param id Widget element ID
#' @param trackName Display name of track
#' @param target Track file path or data object
#' @param validateReference Logical, whether validation is enabled
#' @keywords internal
.validateTrackReference <- function(session,
                                    id,
                                    trackName,
                                    target,
                                    validateReference = TRUE) {
  if (!isTRUE(validateReference)) {
    return(invisible(NULL))
  }

  tryCatch({
    genomeSpec <- .getGenomeSpec(session, id)
    if (is.null(genomeSpec)) {
      return(invisible(NULL))
    }

    compat <- checkReferenceCompatibility(target = target, genomeSpec = genomeSpec,
                                          session = session, id = id)

    if (isFALSE(compat$compatible) && length(compat$mismatches) > 0L) {
      full_msg <- sprintf(
        "igvShiny: Reference incompatibility detected for track '%s':\n%s",
        trackName,
        paste("  *", compat$mismatches, collapse = "\n")
      )

      # 1. Console warning
      warning(full_msg, call. = FALSE)

      # 2. Logger warning
      futile.logger::flog.warn(full_msg)

      # 3. Shiny UI toast notification
      if (!is.null(session) && is.function(session$sendNotification)) {
        toast_msg <- sprintf("Track '%s' reference warning: %s", trackName, compat$mismatches[1])
        shiny::showNotification(
          ui = toast_msg,
          type = "warning",
          duration = 10,
          session = session
        )
      }
    }
  }, error = function(e) {
    futile.logger::flog.debug(sprintf("igvShiny: reference check failed with error: %s", conditionMessage(e)))
  })

  invisible(NULL)
}
