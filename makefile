default:
	@echo available targets: roxy install test demo all

all: roxy install test demo

roxy:
	R -e "devtools::document()"

install:
	R CMD INSTALL .  --no-test-load

test:
	(cd inst/unitTests; make)
demo:
	(cd inst/demos; R -f igvShinyDemo.R)

demo-customGenomeHttp:
	(cd inst/demos; R -f igvShinyDemo-customGenome-http.R)

demo-customGenomeLocalFiles:
	(cd inst/demos; R -f igvShinyDemo-customGenome-localFiles.R)

demo-sars:
	(cd inst/demos; R -f customGenome-localFiles-sars.R)

demo2:
	(cd inst/demos; R -f igvShinyDemo-twoInstances.R)

moduleDemo:
	(cd inst/demos; R -f igvShinyDemo-withModules.R)

rstudio:
	open -a Rstudio  inst/demos/customGenome-localFiles-sars.R
