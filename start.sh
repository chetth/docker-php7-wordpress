#!/bin/sh
NPROC=`grep -c ^processor /proc/cpuinfo 2>/dev/null || 1`
cat <<EOF > /opt/openresty/nginx/conf/nginx.conf
worker_processes $NPROC;
daemon           on;

#pid             logs/nginx.pid;
#user            nobody;

events { worker_connections  200000; }

http {
	include       mime.types;
	default_type  application/octet-stream;

	client_body_buffer_size      10K;
	client_header_buffer_size     1k;
	client_max_body_size           0;
	large_client_header_buffers 2 1k;

	log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	'\$status \$body_bytes_sent "\$http_referer" '
	'"\$http_user_agent" "\$http_x_forwarded_for"';

	access_log  logs/access.log  main;
	sendfile             on;
	#tcp_nopush          on;
	keepalive_timeout   120;
	lua_package_path    "/opt/openresty/lualib/?.lua;;";

	gzip                 on;

	server {
		listen 80 default_server;
		server_name _;
		log_not_found off;
		access_log /dev/stdout;
		error_log /dev/stderr;

		charset utf-8;
		client_max_body_size    0;
		client_header_timeout   360;
		client_body_timeout     360;
		fastcgi_read_timeout    360;
		keepalive_timeout       360;
		proxy_ignore_client_abort on;
		send_timeout            360;
		lingering_timeout       360;

		root    /var/www/html;
		index   index.php index.html;

		location / {
			try_files        \$uri \$uri/ /index.php\$is_args\$args;
		}

		location = /favicon.ico { log_not_found off; }

		location ~ \.php$ {
			include fastcgi.conf;
			include fastcgi_params;
			fastcgi_param PHP_VALUE "upload_max_filesize=512M \n post_max_size=128M";
			fastcgi_read_timeout 180s;
			fastcgi_send_timeout 180s;
			fastcgi_connect_timeout 1200s;
			fastcgi_intercept_errors on;
			fastcgi_pass 127.0.0.1:9000;
			fastcgi_max_temp_file_size 0;
		}
		include /opt/openresty/nginx/conf/conf.d/*.conf;
	}


	include /opt/openresty/nginx/conf/site/*;
}
EOF
/opt/openresty/nginx/sbin/nginx
php-fpm
