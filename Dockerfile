FROM rocker/binder:4.0.3


## Copies your repo files into the Docker Container
USER root

RUN RSTUDIO_VERSION=1.3.959 /rocker_scripts/install_rstudio.sh
COPY . ${HOME}
## Enable this to copy files from the binder subdirectory
## to the home, overriding any existing files.
## Useful to create a setup on binder that is different from a
## clone of your repository
## COPY binder ${HOME}
RUN chown -R ${NB_USER} ${HOME}

## Become normal user again
USER ${NB_USER}
RUN R -e "devtools::install_deps(dep=TRUE)"


