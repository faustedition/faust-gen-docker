Preliminary instructions:

```bash
git clone --recursive --remote https://github.com/faustedition/faust-gen-docker
cd faust-gen-docker
docker compose up --build
```

To build the old versions of the site, we need a copy of the compiled _www_ tree of the respective copy (which can theoretically of course be built from git). Then, assuming the old version 1.0rc is in old/1.0rc, run:

```bash
docker build --target=www-old --build-arg=WWW=old/1.0rc --tag=faustedition/www:1.0rc .
```

to produce a properly tagged image.
