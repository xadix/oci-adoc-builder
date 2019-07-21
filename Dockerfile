# syntax = docker/dockerfile:experimental
ARG os_name=alpine
ARG os_version=3.10
ARG base_image_registry=docker.io
ARG base_image_name=${os_name}
ARG base_image_tag=${os_version}
FROM ${base_image_registry}/${base_image_name}:${base_image_tag}

ARG cache_clean=true
ARG cache_enabled=false

RUN \
	echo "cache_clean=${cache_clean} cache_enabled=${cache_enabled}" && \
    if ${cache_enabled}; then \
        mkdir -p /var/cache/apk && \
        ln -vfs /var/cache/apk /etc/apk/cache && \
        true; \
    else \
        echo "Not enabling cache for apk" && \
        true; \
    fi; \
