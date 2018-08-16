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

### open-falcon start

```go
package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/open-falcon/falcon-plus/g"
	"github.com/spf13/cobra"
)

// open-falcon start 子命令定义
var Start = &cobra.Command{
	Use:   "start [Module ...]",
	Short: "Start Open-Falcon modules",
	Long: `
Start the specified Open-Falcon modules and run until a stop command is received.
A module represents a single node in a cluster.
Modules:
	` + "all " + strings.Join(g.AllModulesInOrder, " "),
	RunE:          start,
	SilenceUsage:  true,
	SilenceErrors: true,
}

// 对应 --preq-order 参数
var PreqOrderFlag bool
// 对应 --console-output 参数
var ConsoleOutputFlag bool

func cmdArgs(name string) []string {
	return []string{"-c", g.Cfg(name)}
}

func openLogFile(name string) (*os.File, error) {
	logDir := g.LogDir(name)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return nil, err
	}

	logPath := g.LogPath(name)
	logOutput, err := os.OpenFile(logPath, os.O_CREATE|os.O_RDWR|os.O_APPEND, 0666)
	if err != nil {
		return nil, err
	}

	return logOutput, nil
}

func execModule(co bool, name string) error {
	// 下面是agent模块的启动示例:
	// 		/<prefix>/agent/bin/falcon-agent -c /<prefix>/agent/config/cfg.json
	cmd := exec.Command(g.Bin(name), cmdArgs(name)...)

	// 对应 --console-output 参数
	if co {
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}

	// 重定向 stdout & stderr 到日志文件
	// PS: 日志设计成接口, 支持多种backend比较好, 例如: rsyslog
	logOutput, err := openLogFile(name)
	if err != nil {
		return err
	}
	defer logOutput.Close()
	cmd.Stdout = logOutput
	cmd.Stderr = logOutput
	return cmd.Start()
}

func checkStartReq(name string) error {
	if !g.HasModule(name) {
		return fmt.Errorf("%s doesn't exist", name)
	}

	if !g.HasCfg(name) {
		r := g.Rel(g.Cfg(name))
		return fmt.Errorf("expect config file: %s", r)
	}

	return nil
}

func isStarted(name string) bool {
	// 1s内, 每100ms检测模块是否成功启动
	ticker := time.NewTicker(time.Millisecond * 100)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			if g.IsRunning(name) {
				return true
			}
		case <-time.After(time.Second):
			return false
		}
	}
}

func start(c *cobra.Command, args []string) error {
	// 参数去重, 防止重复启动模块
	args = g.RmDup(args)

	// 是否需要按特定顺序启动模块, 对应 --preq-order 参数
	if PreqOrderFlag {
		args = g.PreqOrder(args)
	}

	// 默认开启全部模块
	if len(args) == 0 {
		args = g.AllModulesInOrder
	}

	for _, moduleName := range args {
		// 判断模块和配置文件是否存在
		if err := checkStartReq(moduleName); err != nil {
			return err
		}

		// 跳过已运行的模块
		if g.IsRunning(moduleName) {
			fmt.Print("[", g.ModuleApps[moduleName], "] ", g.Pid(moduleName), "\n")
			continue
		}

		// 启动模块
		if err := execModule(ConsoleOutputFlag, moduleName); err != nil {
			return err
		}

		// 打印启动状态

		if isStarted(moduleName) {
			fmt.Print("[", g.ModuleApps[moduleName], "] ", g.Pid(moduleName), "\n")
			continue
		}

		return fmt.Errorf("[%s] failed to start", g.ModuleApps[moduleName])
	}
	return nil
}
```

### open-falcon stop

```go
package cmd

func stop(c *cobra.Command, args []string) error {
	args = g.RmDup(args)

	if len(args) == 0 {
		args = g.AllModulesInOrder
	}

	for _, moduleName := range args {
		// 检测模块是否存在
		if !g.HasModule(moduleName) {
			return fmt.Errorf("%s doesn't exist", moduleName)
		}

		// 模块没有运行则打印信息并跳过
		if !g.IsRunning(moduleName) {
			fmt.Print("[", g.ModuleApps[moduleName], "] down\n")
			continue
		}

		// 以 `open-falcon stop agent` 来举例:
		// 		kill -TERM <从pid文件中读取的模块pid>
		cmd := exec.Command("kill", "-TERM", g.Pid(moduleName))
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		err := cmd.Run()
		if err == nil {
			fmt.Print("[", g.ModuleApps[moduleName], "] down\n")
			continue
		}
		return err
	}
	return nil
}
```

```go
cmd := exec.Command("kill", "-TERM", g.Pid(moduleName))
```

上述代码中的 `g.Pid(moduleName)` 需要解释下, 请直接看下面带注释的实现:

```go
var PidOf map[string]string

var (
	PidOf = map[string]string{
		"agent":      "<NOT SET>",
		"aggregator": "<NOT SET>",
		"graph":      "<NOT SET>",
		"hbs":        "<NOT SET>",
		"judge":      "<NOT SET>",
		"nodata":     "<NOT SET>",
		"transfer":   "<NOT SET>",
		"gateway":    "<NOT SET>",
		"api":        "<NOT SET>",
		"alarm":      "<NOT SET>",
	}
)

func setPid(name string) {
	// 使用 `pgrep -f falcon-agent` 来获取进程pid
	// PS: 这里应该判断进程没有运行的情况, 以及同名程序的情况
	output, _ := exec.Command("pgrep", "-f", ModuleApps[name]).Output()
	pidStr := strings.TrimSpace(string(output))
	PidOf[name] = pidStr
}

func Pid(name string) string {
	// 模块pid没有被设置的话, 检查当前运行的进程中是否有对应模块, 并写入pid文件
	// PS: 其实返回值应该是 （string, error) 形式, 这个实现不严谨, 异常情况下报错会让用户看不懂
	if PidOf[name] == "<NOT SET>" {
		setPid(name)
	}
	return PidOf[name]
}
```

### open-falcon restart

```go
func restart(c *cobra.Command, args []string) error {
	args = g.RmDup(args)

	if len(args) == 0 {
		args = g.AllModulesInOrder
	}

	// open-falcon restart agent
	// 相当于执行:
	//		open-falcon stop agent
	//		open-falcon start agent
	for _, moduleName := range args {
		if err := stop(c, []string{moduleName}); err != nil {
			return err
		}
		if strings.Contains(moduleName, "graph") {
			time.Sleep(2 * time.Second)
		} else {
			time.Sleep(1 * time.Second)
		}
		if err := start(c, []string{moduleName}); err != nil {
			return err
		}
	}
	return nil
}
```

### open-falcon reload

目前还不支持 reload 操作, 代码就不列出了。

### open-falcon check

```go
func check(c *cobra.Command, args []string) error {
	args = g.RmDup(args)

	if len(args) == 0 {
		args = g.AllModulesInOrder
	}

	for _, moduleName := range args {
		// 检测模块是否存在
		if !g.HasModule(moduleName) {
			return fmt.Errorf("%s doesn't exist", moduleName)
		}

		/*
./open-falcon check
	falcon-graph         UP           53007
	  falcon-hbs         UP           53014
	falcon-judge         UP           53020
 falcon-transfer         UP           53026
   falcon-nodata         UP           53032
falcon-aggregator         UP           53038
	falcon-agent         UP           53044
  falcon-gateway       DOWN           -
	  falcon-api         UP           53056
	falcon-alarm         UP           53063
		 */
		if g.IsRunning(moduleName) {
			fmt.Printf("%20s %10s %15s \n", g.ModuleApps[moduleName], "UP", g.Pid(moduleName))
		} else {
			fmt.Printf("%20s %10s %15s \n", g.ModuleApps[moduleName], "DOWN", "-")
		}
	}

	return nil
}
```

### open-falcon monitor

```go
func monitor(c *cobra.Command, args []string) error {
	if len(args) < 1 {
		return c.Usage()
	}
	var tailArgs []string = []string{"-f"}
	for _, moduleName := range args {
		// 判断模块是否存在 & 是否有日志文件
		if err := checkMonReq(moduleName); err != nil {
			return err
		}

		tailArgs = append(tailArgs, g.LogPath(moduleName))
	}
	// ./open-falcon monitor agent graph
	// 相当于执行:
	// tail -f <agent_log_path> <graph_log_path>
	cmd := exec.Command("tail", tailArgs...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
```

## 参考资料

* [Automatic Variables](https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html)
