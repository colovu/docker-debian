# 简介

[Debian 系统](https://www.debian.org/)的基础 Docker 镜像。基于官方 [Debian LTS 版本 slim](https://hub.docker.com/_/debian) 镜像。

**版本信息：**

- 9、stretch、latest



**镜像信息：**

* 镜像地址：colovu/debian:latest
  * 依赖镜像：debian:TAG-slim



与官方镜像差异：

- 修改默认源为阿里云镜像

```shell
deb http://mirrors.aliyun.com/debian/ stretch main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ stretch main contrib non-free

deb http://mirrors.aliyun.com/debian/ stretch-updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ stretch-updates main contrib non-free

deb http://mirrors.aliyun.com/debian/ stretch-proposed-updates main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ stretch-proposed-updates main contrib non-free

deb http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free
deb-src http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free
```

- 增加locales，并默认设置为`en_US.utf8`
- 增加gosu



## 数据卷

该容器没有定义默认的数据卷。该容器仅用作创建其他业务容器的基础容器。



## 使用说明

### 镜像管理

下载镜像：

```shell
docker pull colovu/debian:latest
```

- latest：为镜像的TAG，可针对性选择不同的TAG进行下载



查看镜像：

```shell
docker images
```



### 启动容器

生成并运行一个新的容器：

```shell
docker run -it --rm colovu/debian:latest /bin/bash
```

- `-it`：使用交互式终端启动容器
- `--rm`：退出时删除容器
- `colovu/debian:latest`：包含版本信息的镜像名称
- `/bin/bash`：在容器中执行`/bin/bash`命令；如果不执行命令，容器会在启动后立即结束并退出。



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)

