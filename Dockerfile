FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
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
RUN yum -y install nodejs npm
ADD https://releases.hashicorp.com/consul/1.0.7/consul_1.0.7_linux_amd64.zip ${HOME}/rpmbuild/SOURCES/consul.zip
ADD https://releases.hashicorp.com/consul-template/0.19.4/consul-template_0.19.4_linux_amd64.zip ${HOME}/rpmbuild/SOURCES/consul-template.zip
COPY configure.spec ${HOME}/rpmbuild/SPECS/
COPY SOURCES/* ${HOME}/rpmbuild/SOURCES/
RUN chown -R builder:builder .
USER builder
CMD ["/usr/bin/rpmbuild","-bb","-D","CHIP_IN_REVISION 3","rpmbuild/SPECS/configure.spec"]
