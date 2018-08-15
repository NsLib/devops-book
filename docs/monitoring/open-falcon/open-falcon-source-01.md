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
# Hello, I'm Falcon+ (｡A｡)
```

## 项目结构

```
├── cmd                 // open-falcon程序的子命令
├── common              // 不同module共享的工具、model等
│   ├── backend_pool
│   ├── db
│   ├── model
│   ├── proc
│   ├── sdk
│   └── utils
├── config              // 配置文件例子
├── docker              // 使用docker进行编排、开发
│   └── config
├── docs                // 文档(剖析过程中不关注)
│   ├── _includes
│   ├── _layouts
│   ├── _posts
│   └── doc
├── g
├── logos
├── modules             // 子模块, 每个独立模块一个目录
│   ├── agent
│   ├── aggregator
│   ├── alarm
│   ├── api
│   ├── gateway
│   ├── graph
│   ├── hbs
│   ├── judge
│   ├── nodata
│   └── transfer
├── scripts
│   └── mysql           // 存放数据库建表语句等信息
├── test                // 没有测试, 忽略...
├── vagrant 
├── Makefile
├── VERSION
├── main.go
└── version.go
```

## 剖析

### Makefile

限于篇幅原因，这里只挑选一些重点、难点进行讲解。

```makefile
CMD = agent aggregator graph hbs judge nodata transfer gateway api alarm
TARGET = open-falcon

all: $(CMD) $(TARGET)

$(CMD):
	go build -o bin/$@/falcon-$@ ./modules/$@

.PHONY: $(TARGET)
$(TARGET): $(GOFILES)
	go build -ldflags "-X main.GitCommit=`git rev-parse --short HEAD` -X main.Version=$(VERSION)" -o open-falcon
```


```makefile
$(CMD):
	go build -o bin/$@/falcon-$@ ./modules/$@`
```

上述规则中, 有一个特殊的变量 `$@`, 其代表的是目标规则的名字, 当目标有多个的话, `$@` 代表的是触发规则的那个目标名称, 请看下面示例:

```makefile
# 此时, $@ = foo
foo:
	echo $@
```

```makefile
CMD = a b c d e

# 当执行 make b --always-make 时, $@ = b
# 当执行 make c --always-make 时, $@ = c
$(CMD):
	echo $@
```

```makefile
$(TARGET): $(GOFILES)
	go build -ldflags "-X main.GitCommit=`git rev-parse --short HEAD` -X main.Version=$(VERSION)" -o open-falcon
```

上面的 `-X main.Version=$(VERSION)` 表示在编译期间, 设置 `package main` 中的 `Version` 变量, 这在 Go 语言的开发中是比较常见的一个技巧, 像版本信息这种信息, 不应该写死在代码里, 应该构建时注入进去, 以便与版本控制系统等集成。

### open-falcon命令

open-falcon 命令的构建规则如下所示:

```makefile
TARGET = open-falcon
GOFILES := $(shell find . -name "*.go" -type f -not -path "./vendor/*")
VERSION := $(shell cat VERSION)

.PHONY: $(TARGET)
$(TARGET): $(GOFILES)
	go build -ldflags "-X main.GitCommit=`git rev-parse --short HEAD` -X main.Version=$(VERSION)" -o open-falcon
```

程序的入口点在 `./main.go` 中, 下面去掉了注释、错误处理等, 只保留核心逻辑:

```go
package main

import (
	"fmt"
	"os"

	"github.com/open-falcon/falcon-plus/cmd"
	"github.com/spf13/cobra"
)

var versionFlag bool

// open-falcon 命令本身, 子命令注册见 init()
var RootCmd = &cobra.Command{
	Use: "open-falcon",
	RunE: func(c *cobra.Command, args []string) error {
		if versionFlag {
			fmt.Printf("Open-Falcon version %s, build %s\n", Version, GitCommit)
			return nil
		}
		return c.Usage()
	},
}

func init() {
	// 子命令注册, 其实现源码在 cmd/<subcommand>.go 文件中
	// 每个子命令一个单独文件, 这也是cobra库推荐的最佳实践
	RootCmd.AddCommand(cmd.Start)
	RootCmd.AddCommand(cmd.Stop)
	RootCmd.AddCommand(cmd.Restart)
	RootCmd.AddCommand(cmd.Check)
	RootCmd.AddCommand(cmd.Monitor)
	RootCmd.AddCommand(cmd.Reload)

	// 添加全局参数
	RootCmd.Flags().BoolVarP(&versionFlag, "version", "v", false, "show version")
	cmd.Start.Flags().BoolVar(&cmd.PreqOrderFlag, "preq-order", false, "start modules in the order of prerequisites")
	cmd.Start.Flags().BoolVar(&cmd.ConsoleOutputFlag, "console-output", false, "print the module's output to the console")
}

func main() {
	// 运行命令
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

```


## 参考资料

* [Automatic Variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)
