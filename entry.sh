#!/bin/bash

if [[ ON = "$AUTOINDEX" ]]; then
    sed -i -e '/location \// { p; c \
        autoindex on;
    }' /etc/nginx/conf.d/default.conf
fi

exec "$@"
