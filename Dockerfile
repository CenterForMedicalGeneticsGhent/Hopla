FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \ 
        curl \
        wget \
        libssl-dev \
        libcurl4-openssl-dev \
        build-essential \
    && cd /tmp \
    && wget https://cdn.rstudio.com/r/ubuntu-2404/pkgs/r-4.1.0_1_amd64.deb \
    && apt-get update && apt-get install -y ./r-4.1.0_1_amd64.deb \
    && wget https://github.com/jgm/pandoc/releases/download/2.13/pandoc-2.13-1-amd64.deb \
    && apt-get install -y ./pandoc-2.13-1-amd64.deb \
    && ln -s /opt/R/4.1.0/bin/R /opt/R/4.1.0/bin/Rscript /usr/local/bin/ \
    && R -e "install.packages(c( \
        'vcfR',                  \
        'data.table',            \
        'RColorBrewer',          \
        'kinship2',              \
        'knitr',                 \
        'htmltools',             \
        'plotly'                 \
    ), repos='https://cloud.r-project.org/')" \
    && R -e "install.packages('BiocManager', repos='https://cloud.r-project.org/')" \
    && R -e "BiocManager::install(c('GenomicRanges', 'DNAcopy'))"

RUN wget https://csg.sph.umich.edu/abecasis/merlin/download/merlin-1.1.2.tar.gz \
    && tar -xvzf merlin-1.1.2.tar.gz && cd merlin-1.1.2 && make && make install
    
RUN apt-get purge build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && cd \
    && rm -r /tmp/*

COPY hopla.R /usr/local/bin
RUN chmod a+x /usr/local/bin/hopla.R