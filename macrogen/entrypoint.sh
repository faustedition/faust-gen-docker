#!/bin/sh

. ./graphviewer/bin/activate
. .env
gunicorn graphviewer.gvfa:app
