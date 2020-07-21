# 简介

[Debian 系统](https://www.debian.org/)的基础 Docker 镜像。基于官方 [Debian LTS 版本 slim](https://hub.docker.com/_/debian) 镜像。

**版本信息：**

- 10、10-buster、latest
- 9、9-stretch

**镜像信息：**

* 镜像地址：colovu/debian:latest
  * 依赖镜像：debian:TAG-slim

**与官方镜像差异：**

- 增加 `default、tencent、ustc、aliyun、huawei` 源配置文件，可在编译时通过 `ARG` 变量`apt_source`进行选择
- 更新已安装的软件包
- 增加`locales`，并设置默认编码格式为`en_US.utf8`
- 增加`gosu`
- 设置默认时区信息为 `Asia/Shanghai`



## 使用说明

**下载镜像：**

```shell
docker pull colovu/debian:latest
```

- latest：为镜像的TAG，可针对性选择不同的TAG进行下载

**查看镜像：**

```shell
docker images
```

**生成并运行容器：**

```shell
docker run -it --rm colovu/debian:latest /bin/bash
```

- `-it`：使用交互式终端启动容器
- `--rm`：退出时删除容器
- `colovu/debian:latest`：包含版本信息的镜像名称
- `/bin/bash`：在容器中执行`/bin/bash`命令；如果不执行命令，容器会在启动后立即结束并退出。



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



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)

