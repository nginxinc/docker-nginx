#!/bin/sh

exec envsubst "$(printf '${%s} ' $(env | cut -d= -f1))"
