FROM centos:7
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
RUN mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo "%_topdir %(echo $HOME)/rpmbuild" > ~/.rpmmacros
RUN yum -y install rpmdevtools make deltarpm rsync
RUN yum -y install epel-release
# work around for https://bugs.centos.org/view.php?id=13669&nbn=8
RUN rpm -ivh https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm
# move consul install script to Dockerfile of core
# ADD https://releases.hashicorp.com/consul/1.5.1/consul_1.5.1_linux_amd64.zip ${HOME}/rpmbuild/SOURCES/consul.zip
# ADD https://releases.hashicorp.com/consul-template/0.20.0/consul-template_0.20.0_linux_amd64.zip ${HOME}/rpmbuild/SOURCES/consul-template.zip
COPY configure.spec ${HOME}/rpmbuild/SPECS/
COPY SOURCES/* ${HOME}/rpmbuild/SOURCES/
RUN chown -R builder:builder .
USER builder
CMD ["/usr/bin/rpmbuild","-bb","-D","CHIP_IN_RELEASE 0","-D","CHIP_IN_VERSION 0.0.0","rpmbuild/SPECS/configure.spec"]
