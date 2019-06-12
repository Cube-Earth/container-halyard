FROM debian:latest

RUN apt-get update && apt-get -y upgrade && apt-get install -y curl sudo procps && \
	useradd -s /sbin/nologin user && \
	echo "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list && \
	apt-get update && \
	cd /tmp && \
	curl -O https://raw.githubusercontent.com/spinnaker/halyard/master/install/debian/InstallHalyard.sh && \
	chmod +x InstallHalyard.sh && \
	sed -i'' 's#^install_halyard$#install_halyard\n/tmp/modify_halyard.sh#' InstallHalyard.sh && \
	echo "sed -i'' 's/^HALYARD_STARTUP_TIMEOUT_SECONDS=.*$/HALYARD_STARTUP_TIMEOUT_SECONDS=400/' /usr/local/bin/hal" > modify_halyard.sh && \
	chmod +x /tmp/modify_halyard.sh && \
	echo "\n" | ./InstallHalyard.sh --user user 
	
RUN curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
	chmod +x /usr/local/bin/kubectl
	
RUN curl -L https://git.io/get_helm.sh | bash
	
RUN hal config provider aws enable && \
	hal config provider azure enable && \
	hal config provider kubernetes enable
	
RUN apt-get install -y net-tools

RUN echo "=============================" && \
	hal -v && \
	echo "============================="
	
RUN chown -R user /home/user
	
ADD run.sh /usr/local/bin/

WORKDIR /tmp

##	SHELL=/bin/sh sudo -u user /tmp/InstallHalyard.sh
## sudo -u user -s bash

USER user

RUN helm init --client-only --tiller-namespace tiller

EXPOSE 8064

ENTRYPOINT [ "/usr/local/bin/run.sh" ]

