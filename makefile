default:
	@echo available targets: roxy install demo all

all: roxy install demo

roxy:
	R -e "devtools::document()"

install:
	R CMD INSTALL .  --no-test-load

test:
	(cd inst/unitTests; make)
demo:
	(cd inst/demos; R -f igvShinyDemo.R)

demo2:
	(cd inst/demos; R -f igvShinyDemo-twoInstances.R)

moduleDemo:
	(cd inst/demos; R -f igvShinyDemo-withModules.R)

rstudio:
	open -a Rstudio  inst/demos/igvShinyDemo.R
