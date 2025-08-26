# nyaa-proxy

Hacky nyaa proxy.

Features include Anubis to protect from scraper bots, banner showing the end user that it's a mirror, certain endpoints such as /login and /upload being disabled, and other minor changes.

## Usage

Deploy 3 servers. One of them will serve as a front end and the other two will act as upstream proxies. If you want more than 2 upstream proxies you will need to make changes to the Nginx configuration.

### Front end server

**NB! Ensure you're running this on a server with a valid domain name configured. Without this, nginx-acme will fail to get a Lets Encrypt certificate.**

Clone the repository and set your cwd to `master/`

#### Setup .env

```shell
DOMAIN_NAME=example.com
CADDY_1=192.0.2.45
CADDY_2=198.51.100.77
```

#### Build and start the container

```shell
docker compose up -d
```

### Upstream proxies

Clone the repository and set your cwd to `slave/`.

#### Generate a certificate

Generate a self-signed certificate for both upstream proxies. Ensure you are using SANs with IP-addresses for both proxies.

Place `cert.pem` and `key.pem` in `conf/`.

#### Setup .env

```
# This doesn't need to be resolvable but does show up in a HTTP header
DOMAIN_NAME=caddy-1.example.com
MASTER_IP=203.0.113.128
```

#### Start the container

```shell
docker compose up -d
```

## FAQ

### Why are the upstream proxies using Caddy instead of Nginx?

Nginx by itself can't properly proxy nyaa for some reason. Page loads are very inconsistent.

I think this is because Nginx isn't able to proxy upstream with HTTP/2 and defaults to HTTP/1.1.

### Why is Nginx used as the front end instead of Caddy?

Because I want to inject html into the content served to the client.

This would be possible in Caddy using the [replace-response](https://github.com/caddyserver/replace-response) module. However, it will only work if the upstream returns non-gzipped content. Even if you set proper HTTP headers (Accept-Encoding: identity), nyaa still returns gzipped HTML on some pages.

Using Nginx, I was able to get html injection working with the [`ngx_http_sub_module` module](https://nginx.org/en/docs/http/ngx_http_sub_module.html), albeit only by using a patched `ngx_http_gunzip_filter_module` module.

The patched module essentially decompresses all gzipped content from upstream with the `text/html` MIME type, making it possible to inject HTML. However, this means Nginx can no longer serve gzipped content to the client, which I’m willing to accept.

#### Wouldn't patching Caddy be a better solution?

Probably.