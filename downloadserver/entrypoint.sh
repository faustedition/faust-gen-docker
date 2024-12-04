#!/bin/sh

. ./downloadserver/bin/activate
/opt/downloads/downloadserver/bin/gunicorn "$@"
