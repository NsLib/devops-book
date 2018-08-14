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

# 首先在本地构建用于测试的镜像
docker build -f Dockerfile.build-env -t local/open-falcon-hacking:latest .

# 使用docker compose编排测试依赖
cd docker
docker-compose up -d falcon-plus
```
