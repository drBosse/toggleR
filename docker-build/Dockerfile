FROM rocker/tidyverse:3.6.3

ARG DOCKER_USER

USER root

RUN installGithub.r $DOCKER_USER/toggleR \
&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds
