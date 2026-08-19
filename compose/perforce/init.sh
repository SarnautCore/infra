#!/bin/bash
set -euo pipefail

mkdir -p "$P4ROOT" "$P4DEPOTS" "$P4CKP"

if [ -f "$P4ROOT/root/db.config" ]; then
    if [ ! -L /etc/perforce ] || [ "$(readlink /etc/perforce)" != "$P4ROOT/etc" ]; then
        if [ -e /etc/perforce ] && [ ! -L /etc/perforce ]; then
            mv /etc/perforce "/etc/perforce.orig.$(date +%s)"
        fi
        ln -sfn "$P4ROOT/etc" /etc/perforce
    fi
    p4dctl start -t p4d "$NAME"
else
    mkdir -p "$P4ROOT/etc"
    cp -r /etc/perforce/. "$P4ROOT/etc/"
    mv /etc/perforce /etc/perforce.orig
    ln -s "$P4ROOT/etc" /etc/perforce

    env -u P4PASSWD /opt/perforce/sbin/configure-helix-p4d.sh \
        "$NAME" -n -p "$P4PORT" -r "$P4ROOT" -u "$P4USER" \
        -P "$P4BOOTSTRAP_PASSWORD" --case "$P4CASE" --unicode

    p4 configure set "$P4NAME#server.depot.root=$P4DEPOTS"
    p4 configure set "$P4NAME#journalPrefix=$P4CKP/$JNL_PREFIX"
    p4dctl start -t p4d "$NAME"
fi

printf '%s\n' "$P4BOOTSTRAP_PASSWORD" | p4 login >/dev/null
until p4 info -s >/dev/null 2>&1; do
    sleep 1
done

printf 'Triggers:\n' | p4 triggers -i
exec tail -F "$P4ROOT/logs/log"
