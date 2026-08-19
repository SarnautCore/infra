FROM neoocean/helix-p4d:2026.1

COPY init.sh /usr/local/bin/sarnaut-init.sh
RUN chmod 0755 /usr/local/bin/sarnaut-init.sh && \
    sed -i '/highlight "Creating super-user account..."/a\    export -n P4PASSWD' \
        /opt/perforce/sbin/configure-helix-p4d.sh && \
    sed -i '/export -n P4PASSWD/a\    printf '\''%s\\n%s\\n'\'' "$P4PASSWD" "$P4PASSWD" | $P4 passwd >/dev/null\n    printf '\''%s\\n'\'' "$P4PASSWD" | $P4 login >/dev/null' \
        /opt/perforce/sbin/configure-helix-p4d.sh && \
    sed -i '/    highlight "Setting password..."/,/    debug "Confurables setup complete"/c\    debug "Bootstrap password and ticket already configured"' \
        /opt/perforce/sbin/configure-helix-p4d.sh
