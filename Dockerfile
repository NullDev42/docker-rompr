FROM archlinux/archlinux:base-20260317.0.501684 AS builder
ARG ROMPR_VERSION=2.29
ARG ZIP_FILE=rompr-$ROMPR_VERSION.zip
ARG FETCH_URL=https://github.com/fatg3erman/RompR/releases/download/$ROMPR_VERSION/$ZIP_FILE

RUN pacman -Sy --noconfirm apache unzip imagemagick libwmf libjxl php-apache php-sqlite php-gd php-intl python python-websockets python-nest-asyncio wget && \
    rm -rf /var/cache/pacman/pkg && \
    cd / && \
    wget $FETCH_URL && \
    unzip $ZIP_FILE

    # Stage 2: Final
FROM archlinux/archlinux:base-20260317.0.501684 AS final

RUN pacman -Sy --noconfirm apache imagemagick libwmf libjxl php-apache php-sqlite php-gd php-intl python python-websockets python-nest-asyncio && \
    rm -rf /var/cache/pacman/pkg && \
    sed -i 's/;extension=pdo_sqlite/extension=pdo_sqlite/' /etc/php/php.ini && \
    sed -i 's/;extension=sqlite3/extension=sqlite3/' /etc/php/php.ini && \
    sed -i 's/;extension=curl/extension=curl/' /etc/php/php.ini && \
    sed -i 's/;extension=gd/extension=gd/' /etc/php/php.ini && \
    sed -i 's/;extension=intl/extension=intl/' /etc/php/php.ini

# Copy application from builder
COPY --from=builder /rompr /rompr
COPY --from=builder /etc/httpd/conf/ /etc/httpd/conf/

# Copy configuration files from the original project structure
# (Ensure these files are available in your build context)
COPY httpd.conf rompr.conf /etc/httpd/conf/

RUN mkdir -p /rompr/prefs /rompr/albumart && \
    chown -R root:root /rompr && \
    chown -R http:http /rompr/prefs /rompr/albumart

EXPOSE 80
ENTRYPOINT ["/usr/sbin/httpd", "-DFOREGROUND"]
