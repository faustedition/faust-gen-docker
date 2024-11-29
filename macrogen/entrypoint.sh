#!/bin/sh

ls -la

export DEFAULT_MODEL=macrogen-info.zip
. ./graphviewer/bin/activate
env
/opt/macrogen/graphviewer/bin/gunicorn "$@"
