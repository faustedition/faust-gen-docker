worker_class = 'uvicorn.workers.UvicornWorker'
proc_name = 'faust-macrogen-graphviewer'
wsgi_app = 'graphviewer.gvfa:app'
bind = '127.0.0.1:5001'
