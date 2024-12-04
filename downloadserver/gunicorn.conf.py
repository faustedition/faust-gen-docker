accesslog = "-"
capture_output = True
worker_class = "uvicorn.workers.UvicornWorker"
proc_name = "faust-download-server"
wsgi_app = "faust_download_server:app"
bind = "0.0.0.0:5051"
