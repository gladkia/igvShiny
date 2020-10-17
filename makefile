default:
	@echo available targets: roxy install demo all

all: roxy install demo

roxy:
	R -e "devtools::document()"

install:
	R CMD INSTALL .

demo:
	(cd inst/unitTests; R -f igvShinyDemo.R)


