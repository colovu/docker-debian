
current_branch := $(shell git rev-parse --abbrev-ref HEAD)

# Sources List: 163 / debian / tencent / ustc / aliyun / huawei
build-arg := --build-arg apt_source=tencent 
build-arg += --build-arg local_url=http://192.168.200.29/dist-files/

build:
	docker build --force-rm $(build-arg) -t debian:$(current_branch) .
