default:
	@echo available targets: roxy install test demo all

all: roxy install test demo

roxy:
	R -e "devtools::document()"

install:
	R CMD INSTALL .  --no-test-load

test:
	R -e "testthat::test_local()"

# the showcase app: most of the API in one place, and what Posit Connect serves
demo:
	(cd inst/showcase; R -f igvShinyDemo.R)

# one focused app per feature - DEMO=gwas make demo-one
DEMO ?= tiny
demo-one:
	(cd inst/demos; R -f $(DEMO).R)

check-podman:
	podman run --rm -v $$(pwd):/pkg igvshiny-test-env /bin/bash -c "Rscript -e \"gDRstyle::checkPackage('igvShiny', repoDir='.')\""

build-test-env:
	podman build -t igvshiny-test-env -f Containerfile .
