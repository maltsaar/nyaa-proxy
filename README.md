# nyaa-proxy

Hacky nyaa proxy.

Extra features include a banner showing the end user that it's a mirror, certain endpoints such as /login and /upload being disabled, and other minor changes.

## Usage

**NB! Ensure you're running this on a server with a valid domain name configured. Without this, nginx-acme will fail to get a Lets Encrypt certificate.**

### Setup .env

```shell
DOMAIN_NAME=example.com
```

### Build and start the container

```shell
docker compose up -d
```

## FAQ

### Why are there 2 nested proxy servers?

Nginx by itself can't properly proxy nyaa for some reason. Page loads often don't work and seem to result in a 504 half the time. Caddy works fine.

I think this is because Nginx isn't able to proxy upstream with HTTP/2 and defaults to HTTP/1.1.

### Why is Nginx even needed if Caddy works just fine?

Because I want to inject html into the content served to the client.

This would be possible in Caddy using the [replace-response](https://github.com/caddyserver/replace-response) module. However, it will only work if the upstream returns non-gzipped content. Even if you set proper HTTP headers (Accept-Encoding: identity), nyaa still returns gzipped HTML on some pages.

Using Nginx, I was able to get html injection working with the [`ngx_http_sub_module` module](https://nginx.org/en/docs/http/ngx_http_sub_module.html), albeit only by using a patched `ngx_http_gunzip_filter_module` module.

The patched module essentially decompresses all gzipped content from upstream with the `text/html` MIME type, making it possible to inject HTML. However, this means Nginx can no longer serve gzipped content to the client, which I’m willing to accept.

### Wouldn't patching Caddy be a better solution?

Probably.