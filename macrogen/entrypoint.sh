#!/bin/sh

export DEFAULT_MODEL=macrogen-info.zip
. ./graphviewer/bin/activate
/opt/macrogen/graphviewer/bin/gunicorn "$@"
