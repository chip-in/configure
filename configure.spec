%define		debug_package %{nil}
Name: chip-in-configure
Version: 1.0.0
Release: %{CHIP_IN_REVISION}%{?dist}
Group: Applications/System
Summary: Auto configuration tool for chip-in core node system
Packager: "Mitsuru Nakakawaji" <mitsuru@procube.jp>
Source0: configure
License:	MIT
Requires:	nodejs
Requires:	npm
Requires:	nginx

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
unzip consul.zip -d $RPM_BUILD_ROOT/usr/bin
unzip consul-template -d $RPM_BUILD_ROOT/usr/bin
install chip-in-config.sh.tmpl $RPM_BUILD_ROOT/usr/lib/chip-in
install functions.sh $RPM_BUILD_ROOT/usr/lib/chip-in
install consul.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install chip-in-config.service $RPM_BUILD_ROOT/usr/lib/systemd/system
install consul.conf $RPM_BUILD_ROOT/etc
install default.conf $RPM_BUILD_ROOT/usr/lib/chip-in
echo "[]" > $RPM_BUILD_ROOT/etc/chip-in/kvs.json

%files
%defattr(644,root,root,755)
%attr(755,root,root) /usr/bin/consul
%attr(755,root,root) /usr/bin/consul-template
/usr/lib/systemd/system/*
/usr/lib/chip-in
/etc
/var/consul

%post
if [ "$1" = "1" ]; then
  cp -p /usr/lib/chip-in/default.conf /etc/nginx/conf.d/default.conf
fi

%changelog
