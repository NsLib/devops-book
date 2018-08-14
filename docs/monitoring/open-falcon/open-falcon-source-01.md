# Open-Falcon源码剖析——开篇

## 说明

* 系统: macOS 10.13.6
* Docker: 18.03.1-ce-mac65
* Go: 1.9.4
* Git: 2.12.0
* govendor: 1.0.9

## 准备工作

下载源码：

```bash
# 这个是笔者测试用的分支, 不是官方版本
# 官方版本: https://github.com/open-falcon/falcon-plus
git clone git@github.com:NsLib/falcon-plus.git $GOPATH/src/github.com/open-falcon/falcon-plus

cd $GOPATH/src/github.com/open-falcon/falcon-plus

# 切换到我们测试用的分支
git checkout -t origin/hacking

# 首先构建一个用于编译open-falcon的镜像, 后面我们测试过程中, 会反复使用, 一定要先配置好
docker build -f Dockerfile.build-env -t local/open-falcon-build-env:latest .

# 使用docker编译open-falcon, 构建结果会保存在宿主机的bin目录内, 后面docker compose编排时会被使用
docker run -v $GOPATH:/go local/open-falcon-build-env:latest /bin/bash -c 'cd /go/src/github.com/open-falcon/falcon-plus && make -f Makefile.dev dev'

# 构建一个用于docker-compose的镜像
docker build -f Dockerfile.dev -t local/open-falcon-dev:latest .

# 使用docker compose编排测试依赖
cd docker
docker-compose up -d falcon-plus

# 测试服务是否正常
curl http://localhost:8080
```
