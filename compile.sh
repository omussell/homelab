#!/bin/sh
cd ~/nginx/nginx-1.13.0/
#make clean

./configure \
	--with-http_ssl_module \
#	--with-http-spdy_module \
	--with-http_gzip_static_module \
	--with-file-aio \
	--with-ld-opt="-L /usr/local/lib" \

#	--without-http_autoindex_module \
	--without-http_browser_module \
	--without-http_fastcgi_module \
	--without-http_geo_module \
	--without-http_map_module \
	--without-http_proxy_module \
	--without-http_memcached_module \
	--without-http_ssi_module \
	--without-http_userid_module \
	--without-http_split_clients_module \
	--without-http_uwsgi_module \
	--without-http_scgi_module \
	--without-http_limit_conn_module \
	--without-http_referer_module \
	--without-http_http-cache \
	--without_upstream_ip_hash_module \
	--without-mail_pop3_module \
	--without-mail-imap_module \
	--without-mail_smtp_module

	--with-openssl=~/nginx/openssl-1.1.0e/

make
make install
