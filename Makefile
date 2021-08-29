serve:
	podman run -p0.0.0.0:1313:1313 -v $$(pwd):/src docker.io/klakegg/hugo server --baseURL=//192.168.1.2

build:
	/bin/rm -rf public resources
	podman run -v $$(pwd):/src docker.io/klakegg/hugo --verbose --debug
