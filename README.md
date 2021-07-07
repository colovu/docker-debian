# Debian

[Debian 系统](https://www.debian.org/)的基础 Docker 镜像。基于官方 [Debian LTS 版本 slim](https://hub.docker.com/_/debian) 镜像。

**版本信息：**

- buster、latest
- 10

**镜像信息：**

* 镜像地址：
  * 阿里云: registry.cn-shenzhen.aliyuncs.com/colovu/debian:latest
  * Docker Hub: colovu/debian:latest
  * 依赖镜像：debian:buster-slim

> 后续相关命令行默认使用`[Docker Hub](https://hub.docker.com)`镜像服务器做说明

**与官方镜像差异：**

- 增加 `default、tencent、ustc、aliyun、huawei` 源配置文件，可在编译时通过 `ARG` 变量`apt_source`进行选择
- 增加常用 Shell 脚本文件
- 更新已安装的软件包
- 增加`locales`，并设置默认编码格式为`en_US.utf8`
- 设置默认时区信息为 `Asia/Shanghai`
- 默认增加 nss_wrapper 支持
- 默认增加 curl 软件，用作镜像健康检查


## TL;DR

Docker 快速启动命令：

```shell
# 从 Docker Hub 服务器下载镜像并启动
$ docker run -it colovu/debian /bin/bash
```



---



## 使用说明

**下载镜像：**

```shell
$ docker pull colovu/debian:buster
```

- buster：为镜像的 TAG，可针对性选择不同的 TAG 进行下载
- 不指定 TAG 时，默认下载 latest 镜像

**查看镜像：**

```shell
$ docker images
```

**命令行方式运行容器：**

```shell
$ docker run -it --rm colovu/debian:buster /bin/bash
```

- `-it`：使用交互式终端启动容器
- `--rm`：退出时删除容器
- `colovu/debian:buster`：镜像名称及版本标签；标签不指定时默认使用`latest`
- `/bin/bash`：在容器中执行`/bin/bash`命令；如果不执行命令，容器会在启动后立即结束并退出。

以该方式启动后，直接进入容器的命令行操作界面。如果需要退出，直接使用命令`exit`退出。

**后台方式运行容器：**

```shell
$ docker run -d --name test colovu/debian:buster tail /dev/stderr
```

- `--name test`：命名容器为`test`
- `-d`：以后台进程方式启动容器
- `colovu/debian:buster`：镜像名称及版本标签；标签不指定时默认使用`latest`
- `tail /dev/stderr`：在容器中执行`tail /dev/stderr`命令，以防止容器直接退出



以该方式启动后，如果想进入容器，可以使用以下命令：

```shell
$ docker exec -it test /bin/bash
```

- `-it`：使用交互式执行
- `test`：之前启动的容器名
- `/bin/bash`：执行的命令


## 配置修改

### 修改时区信息

可在生成镜像时或容器初始化 Shell 脚本中，使用以下命令：

```shell
# 修改时区为 UTC
$ ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# 重新配置系统
$ dpkg-reconfigure -f noninteractive tzdata
```

更新成功后会显示当前时区信息，如：

```shell
Current default time zone: 'Etc/UTC'
Local time is now:      Tue Jul 21 09:16:14 UTC 2020.
Universal Time is now:  Tue Jul 21 09:16:14 UTC 2020.
```



### 修改字符编码格式

可在生成镜像时或容器初始化 Shell 脚本中，使用以下命令：

``` shell
# 更改默认字符编码为 zh_CN.UTF-8
$ sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
$ update-locale LC_ALL=zh_CN.UTF-8 LANG=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 LC_MESSAGES=POSIX
$ dpkg-reconfigure -f noninteractive locales

# 设置环境变量
$ export LC_ALL=zh_CN.UTF-8 LANG=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8
```

更新成功后，可使用`locale`命令查看字符编码信息。


## 更新记录

- buster、latest
  + 删除应用程序 gosu 及 tini
- 10


----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)

