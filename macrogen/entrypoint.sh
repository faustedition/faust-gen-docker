#!/bin/sh

pwd
env
cd /opt/macrogen
export DEFAULT_MODEL=macrogen-info.zip
. /opt/macrogen/graphviewer/bin/activate
/opt/macrogen/graphviewer/bin/gunicorn "$@"
