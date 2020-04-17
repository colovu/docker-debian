# 简介

基于的Alpine系统的Docker镜像。基于官方Debian 8.11镜像。



## 基本信息

* 镜像地址：endial/debian:v8.11
* 依赖镜像：debian:8.11



与官方镜像差异：

- 修改默认源为阿里云镜像

```shell
  deb http://mirrors.aliyun.com/debian/ jessie main contrib non-free
  deb-src http://mirrors.aliyun.com/debian/ jessie main contrib non-free

  deb http://mirrors.aliyun.com/debian/ jessie-updates main contrib non-free
  deb-src http://mirrors.aliyun.com/debian/ jessie-updates main contrib non-free

  #deb http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib
  #deb-src http://mirrors.aliyun.com/debian/ jessie-proposed-updates main non-free contrib

  #deb http://mirrors.aliyun.com/debian/ jessie-backports main contrib non-free
  #deb-src http://mirrors.aliyun.com/debian/ jessie-backports main contrib non-free
```

- 增加locales，并默认设置为`en_US`



## 数据卷

该容器没有定义默认的数据卷。该容器仅用作创建其他业务容器的基础容器。



## 使用说明

### 镜像管理

下载镜像：

```shell
docker pull endial/debian:v8.11
```

查看镜像：

```shell
docker images
```



### 启动容器

生成并运行一个新的容器：

```shell
docker run -it --rm endial/debian:v8.11 /bin/bash
```

- `-it`：使用交互式终端启动容器
- `--rm`：退出时删除容器
- `endial/debian:v8.11`：包含版本信息的镜像名称
- `/bin/bash`：在容器中执行`/bin/bash`命令



----

本文原始来源 [Endial Fang](https://github.com/endial) @ [Github.com](https://github.com)

