FROM bioconductor/bioconductor_docker:devel

# Set environment variables for smooth installation
ENV R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

# Install Chromium (instead of Google Chrome) for ARM64 compatibility
RUN apt-get update && \
    apt-get install -y chromium-browser && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Point chromote to the Chromium executable
ENV CHROMOTE_CHROME=/usr/bin/chromium-browser

# Pre-install core developer packages
RUN Rscript -e "BiocManager::install(c('remotes', 'gDRstyle', 'testthat'), update=FALSE, ask=FALSE)"

# Cache R package dependencies by copying DESCRIPTION first
COPY DESCRIPTION /tmp/DESCRIPTION

# Install local package dependencies safely
RUN Rscript -e "remotes::install_deps(pkgdir='/tmp', dependencies=TRUE, upgrade='never')"

WORKDIR /pkg