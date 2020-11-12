default:
	@echo available targets: roxy install demo all

all: roxy install demo

roxy:
	R -e "devtools::document()"

install:
	R CMD INSTALL .  --no-test-load

demo:
	(cd inst/unitTests; R -f igvShinyDemo.R)

demo2:
	(cd inst/unitTests; R -f igvShinyDemo-twoInstances.R)


