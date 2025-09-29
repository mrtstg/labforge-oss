FROM python:3.13 AS docbuilder
ENV PYTHONUNBUFFERED=1
ENV LANG C.UTF-8
WORKDIR /usr/src/app
RUN apt-get update && apt-get install make -y
RUN pip3 install --no-cache-dir poetry==2.1.2
COPY labforge-docs/pyproject.toml .
RUN poetry install --no-root
COPY labforge-docs/mkdocs.yml labforge-docs/Makefile .
COPY labforge-docs/docs /usr/src/app/docs
RUN make build

FROM nginx:stable-alpine
ARG ssl_dir=deployment/nginx/ssl
ARG config_dir=deployment/nginx/conf.dev
RUN rm -rf /etc/nginx/conf.d/*
COPY deployment/nginx/nginx.conf /etc/nginx/nginx.conf
COPY $ssl_dir /etc/nginx/ssl
COPY $config_dir /etc/nginx/conf.d
COPY --from=docbuilder /usr/src/app/site /etc/nginx/docs
