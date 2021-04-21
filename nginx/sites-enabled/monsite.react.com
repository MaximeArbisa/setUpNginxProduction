################################# monsite.com

# Upstream nodejs processes - load balancer
upstream website_app_server {
  server localhost:3000;
  server localhost:3001;
  server localhost:3002;
  server localhost:3003;
}

# Server- React app
server {
  listen 443 ssl http2; # SSL
  listen [::]:443 ssl http2;
  server_name www.monsite.com monsite.com;

  root /path/to/react/build;
  index index.html;

  location / {
    try_files $uri $uri/ =404;
  }

  ## SSL parameters
  # Include certificates
  ssl_certificate /etc/letsencrypt/live/monsite.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/monsite.com/privkey.pem;

  # openssl dhparam 4096 -out /etc/ssl/dhparam.pem
  # from here: https://scaron.info/blog/improve-your-nginx-ssl-configuration.html
  ssl_dhparam /etc/ssl/certs/dhparam.pem;

  # Include SSL protocol and parameters
  ssl_protocols TLSv1.3 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ecdh_curve secp521r1:secp384r1;
  ssl_ciphers EECDH+CHACHA20:EECDH+AES256:EECDH+AESGCM:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;

  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;

  # OCSP stapling
  ssl_stapling on;
  ssl_stapling_verify on;

  # HSTS (ngx_http_headers_module is required) (63072000 seconds)
  add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
}
  
# Server- Node API
server {
  listen 443 ssl http2; # SSL
  listen [::]:443 ssl http2;
  server_name api.monsite.com;

  ## SSL parameters
  # Include certificates
  ssl_certificate /etc/letsencrypt/live/monsite.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/monsite.com/privkey.pem;

  # openssl dhparam 4096 -out /etc/ssl/dhparam.pem
  # from here: https://scaron.info/blog/improve-your-nginx-ssl-configuration.html
  ssl_dhparam /etc/ssl/certs/dhparam.pem;

  # Include SSL protocol and parameters
  ssl_protocols TLSv1.3 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ecdh_curve secp521r1:secp384r1;
  ssl_ciphers EECDH+CHACHA20:EECDH+AES256:EECDH+AESGCM:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;

  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;

  # OCSP stapling
  ssl_stapling on;
  ssl_stapling_verify on;

  # HSTS (ngx_http_headers_module is required) (63072000 seconds)
  add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;

  location / {
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme; # app redirection towards https
    proxy_buffering off;

    proxy_pass http://website_app_server;
    proxy_redirect http://website_app_server/ /;
  }
}
