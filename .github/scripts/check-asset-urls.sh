#!/usr/bin/env bash
# Check that the external assets igvShiny points at are still reachable.
#
# Stock genomes, example fasta/gff3 files and demo tracks live on hosts we do
# not control (gladki.pl, igv.org, AWS, UCSC, ENCODE). When one starts to 404
# the package keeps passing its tests — the tests deliberately use a local
# httpuv server — but genomes silently fail to display for users. That is how
# #107 reached us, as a bug report. See issue #115.
#
# URLs are scraped from the sources rather than listed here, so the check
# cannot drift away from what the code actually requests.
#
# Usage: .github/scripts/check-asset-urls.sh [--markdown]
# Exit:  0 all reachable, 1 at least one failed.

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 1
cd "$repo_root" || exit 1

markdown=false
[[ "${1:-}" == "--markdown" ]] && markdown=true

# Sources that carry URLs igv.js will actually fetch. The vendored library in
# inst/htmlwidgets/lib is excluded: those are upstream's own URLs, thousands of
# them, and not ours to fix.
sources=(
  inst/htmlwidgets/igvShiny.js
  R
  inst/demos
  vignettes
)

# Placeholder and unreachable-by-design hosts used in documentation examples.
placeholder_re='^https?://(example\.org|127\.0\.0\.1|localhost|a\.bed|b\.bed|\.\.\.)'

# Assembled at run time from a base URL plus a file name, so the scrape below
# only ever sees the directory half. Listed in full because these are the files
# the demos actually fetch.
composed_urls=(
  https://gladki.pl/igvr/testFiles/sarsGenome/Sars_cov_2.ASM985889v3.dna.toplevel.fa
  https://gladki.pl/igvr/testFiles/sarsGenome/Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai
  https://gladki.pl/igvr/testFiles/sarsGenome/Sars_cov_2.ASM985889v3.101.gff3
  https://gladki.pl/igvr/testFiles/ribosomal-RNA-gene.fasta
  https://gladki.pl/igvr/testFiles/ribosomal-RNA-gene.fasta.fai
  https://gladki.pl/igvr/testFiles/ribosomal-RNA-gene.gff3
  https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment/HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam
  https://1000genomes.s3.amazonaws.com/phase3/data/HG02450/alignment/HG02450.mapped.ILLUMINA.bwa.ACB.low_coverage.20120522.bam.bai
  https://s3.amazonaws.com/1000genomes/1000G_2504_high_coverage/additional_698_related/data/ERR3989250/HG04160.final.cram
  https://s3.amazonaws.com/1000genomes/1000G_2504_high_coverage/additional_698_related/data/ERR3989250/HG04160.final.cram.crai
)

# Read into an array without mapfile — macOS still ships bash 3.2.
urls=()
while IFS= read -r url; do
  urls+=("$url")
done < <(
  {
    grep -rhoE 'https?://[^"'"'"'`) ,]+' "${sources[@]}" 2>/dev/null |
      sed -E 's/[.,;:)]+$//' |
      grep -vE "$placeholder_re" |
      grep -vE '^https?://[^/]*%[ds]' |
      # Keep only URLs whose last segment looks like a file. Bare directories
      # (CRAN mirrors, S3 prefixes, base URLs) answer 403/404 by design and
      # would report as permanent failures; the files under them are covered by
      # composed_urls above.
      grep -E '^https?://[^/]+/' |
      grep -E '/[^/]+\.[A-Za-z0-9]+$'
    printf '%s\n' "${composed_urls[@]}"
  } | sort -u
)

if [[ ${#urls[@]} -eq 0 ]]; then
  echo "No URLs found — the scrape is broken, not the assets." >&2
  exit 1
fi

failed=()

check_url() {
  local url="$1" code
  # HEAD first; some static hosts answer it with 403/405, so fall back to a
  # single-byte ranged GET before calling the asset dead.
  code=$(curl -sSL --max-time 30 -o /dev/null -w '%{http_code}' -I "$url" 2>/dev/null)
  if [[ "$code" =~ ^2 ]]; then
    echo "$code"
    return 0
  fi
  code=$(curl -sSL --max-time 30 -o /dev/null -w '%{http_code}' -r 0-0 "$url" 2>/dev/null)
  echo "$code"
  [[ "$code" =~ ^2 ]]
}

printf 'Checking %d external asset URLs\n\n' "${#urls[@]}"

for url in "${urls[@]}"; do
  if code=$(check_url "$url"); then
    printf '  ok   %-6s %s\n' "$code" "$url"
  else
    printf '  FAIL %-6s %s\n' "${code:-000}" "$url"
    failed+=("${code:-000}|$url")
  fi
done

echo
if [[ ${#failed[@]} -eq 0 ]]; then
  printf 'All %d URLs reachable.\n' "${#urls[@]}"
  exit 0
fi

printf '%d of %d URLs unreachable.\n' "${#failed[@]}" "${#urls[@]}"

if $markdown; then
  {
    echo "| HTTP | URL |"
    echo "|------|-----|"
    for entry in "${failed[@]}"; do
      printf '| `%s` | %s |\n' "${entry%%|*}" "${entry#*|}"
    done
  } >"${ASSET_REPORT:-asset-url-report.md}"
fi

exit 1
