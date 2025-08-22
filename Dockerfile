FROM nginx:stable-alpine

RUN apk add --no-cache build-base pcre-dev zlib-dev openssl-dev git cargo clang-dev

RUN git clone --branch master --depth 1 https://github.com/maltsaar/nginx.git /tmp/nginx-src
RUN git clone --branch main --depth 1 https://github.com/nginx/nginx-acme.git /tmp/nginx-acme-src

WORKDIR /tmp/nginx-src
# Copy our patched module into nginx src before we compile
COPY ./src/ngx_http_gunzip_filter_module.c ./nginx/src/http/modules
RUN ./auto/configure \
    --with-debug \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/run/nginx.pid \
    --with-http_ssl_module \
    --with-http_gunzip_module \
    --with-http_sub_module \
    --add-dynamic-module=/tmp/nginx-acme-src
RUN make install
RUN cp ./objs/ngx_http_acme_module.so /etc/nginx/modules

RUN apk del build-base pcre-dev zlib-dev openssl-dev git \
    && rm -rf /tmp/nginx-src /tmp/nginx-acme-src
RUN apk add --no-cache pcre zlib openssl
