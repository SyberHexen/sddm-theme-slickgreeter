#!/bin/sh
# Installs the Slick Greeter-style theme as /usr/share/sddm/themes/slick
# (run as root), keeping the theme.conf.user made there (your settings).
# Then choose it: Current=slick under [Theme] in /etc/sddm.conf.d/*.conf, or
# with SDDM Settings (https://github.com/SyberHexen/sddm-settings).
set -e
here=$(dirname "$(readlink -f "$0")")
dest=/usr/share/sddm/themes/slick

saved=""
if [ -f "$dest/theme.conf.user" ]; then
    saved=$(mktemp)
    cp "$dest/theme.conf.user" "$saved"
fi
rm -rf "$dest"
cp -r "$here/slick" "$dest"
if [ -n "$saved" ]; then
    install -m 644 "$saved" "$dest/theme.conf.user"
    rm -f "$saved"
fi
chmod -R a+rX "$dest"
echo "Installed the Slick theme in $dest"
