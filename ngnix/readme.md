# Install Nginx
sudo apt update
sudo apt install -y nginx

* Check:
sudo systemctl status nginx

# Create the Cloudflare Origin Certificate from cloudflare
In Cloudflare:

SSL/TLS → Origin Server → Create Certificate

# Create ssl directory inside the server where nginx install
sudo mkdir -p /etc/nginx/ssl

* Create the certificate:
sudo nano /etc/nginx/ssl/cuddlyduddly-origin.pem

* Create the private key:
sudo nano /etc/nginx/ssl/cuddlyduddly-origin.key

* Give proper permission
sudo chmod 644 /etc/nginx/ssl/cuddlyduddly-origin.pem
sudo chmod 600 /etc/nginx/ssl/cuddlyduddly-origin.key

# Configure your routing
sudo nano /etc/nginx/sites-available/cuddlyduddly-websites

* Configuration code would be like below
```
############################################
# HTTP -> HTTPS
############################################

server {
    listen 80;
    listen [::]:80;

    server_name apigateway-qa.cuddlyduddly.com;

    return 301 https://$host$request_uri;
}



############################################
# cuddlyduddly.com
# Docker: 127.0.0.1:4101
############################################

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name apigateway-qa.cuddlyduddly.com;

    ssl_certificate     /etc/nginx/ssl/cuddlyduddly-origin.pem;
    ssl_certificate_key /etc/nginx/ssl/cuddlyduddly-origin.key;

    ssl_protocols TLSv1.2 TLSv1.3;

    location / {
        proxy_pass http://127.0.0.1:4101;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

```

# Enable the configuration
sudo ln -s /etc/nginx/sites-available/cuddlyduddly-websites \
           /etc/nginx/sites-enabled/cuddlyduddly-websites

* If the default Nginx site is enabled, remove it:
sudo rm -f /etc/nginx/sites-enabled/default

* test:
sudo nginx -t

* reload nginx:
sudo systemctl reload nginx

