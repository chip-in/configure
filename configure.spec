%define		debug_package %{nil}
Name: chip-in-configure
Version: %{CHIP_IN_VERSION}
Release: %{CHIP_IN_RELEASE}%{?dist}
Group: Applications/System
Summary: Auto configuration tool for chip-in core node system
Packager: "Mitsuru Nakakawaji" <mitsuru@procube.jp>
Source0: configure
License:	MIT
Requires:	nodejs
Requires:	npm
Requires:	nginx
Requires:	mod_ssl

%description

%prep

%build
cp -a ${RPM_SOURCE_DIR}/* .

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/bin
mkdir -p $RPM_BUILD_ROOT/usr/lib/systemd/system
mkdir -p $RPM_BUILD_ROOT/usr/lib/chip-in
mkdir -p $RPM_BUILD_ROOT/etc/chip-in
mkdir -p $RPM_BUILD_ROOT/var/consul
mkdir -p $RPM_BUILD_ROOT/etc/consul.d
mkdir -p $RPM_BUILD_ROOT/etc/nginx/conf.d
mkdir -p $RPM_BUILD_ROOT/etc/nginx/jwt.settings
unzip consul.zip -d $RPM_BUILD_ROOT/usr/bin
unzip consul-template -d $RPM_BUILD_ROOT/usr/bin
install consul-env2conf.sh $RPM_BUILD_ROOT/usr/bin
install consul.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install default.conf $RPM_BUILD_ROOT/usr/lib/chip-in
install deny.template.html $RPM_BUILD_ROOT/etc/nginx/jwt.settings
install error.template.json $RPM_BUILD_ROOT/etc/nginx/jwt.settings
install succeeded.template.json $RPM_BUILD_ROOT/etc/nginx/jwt.settings
install env2htpasswd.sh $RPM_BUILD_ROOT/usr/bin
install functions.sh $RPM_BUILD_ROOT/usr/lib/chip-in
install jwtIssuer-config.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install jwtIssuer.conf.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install jwtIssuer.json.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install cors-common.conf.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install acl.json.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install mosquitto.conf.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install jwtVerifier-config.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install jwtVerifier.conf.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install jwtVerifier.json.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install load-certificates.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install load-certificates.sh $RPM_BUILD_ROOT/usr/bin
install logserver-config.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install logserver.conf.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install metadata-download.sh.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install renewCerts.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install renewCerts.timer $RPM_BUILD_ROOT/usr/lib/systemd/system
install shibboleth-config.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install shibboleth2.xml.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install setting.conf.server $RPM_BUILD_ROOT/etc/nginx/conf.d

%files
%defattr(644,root,root,755)
%attr(755,root,root) /usr/bin/*
/usr/lib/systemd/system/*
/usr/lib/chip-in
/etc/consul.d
/etc/nginx/conf.d
/etc/nginx/jwt.settings
/var/consul

%post
if [ "$1" = "1" ]; then
  cp -p /usr/lib/chip-in/default.conf /etc/nginx/conf.d/default.conf
fi

%changelog
