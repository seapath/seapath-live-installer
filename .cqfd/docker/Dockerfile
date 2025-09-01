#
FROM debian:bookworm
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
	live-build \
	coreutils \
	make \
	build-essential \
	wget \
	git \
	unzip \
	colordiff \
	apt-transport-https \
	rename \
	ovmf \
	rsync \
	python3-venv \
	gnupg \
	sudo \
	cpio \
	apt-utils
RUN echo '%builders    ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
