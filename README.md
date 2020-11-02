# Overview
Go modules 是 Go 语言的依赖解决方案, 使用 go modules 有以下几点好处
1. 工程效率上的提升
2. 统一依赖管理流程，减少在处理依赖问题的时间
3. 方便在 CI/CD 复现构建

## Requirements
- go 1.11+
- set environment variable
	```bash
	# 设置环境变量 GO111MODULE
	go env -w GO111MODULE=on

	# 设置 goproxy 代理
	go env -w GOPROXY=https://goproxy.cn,direct
	# 如果公司内网安装了代理
	go env -w GOPROXY=http://goproxy.example.com,direct

	# 设置 GONOSUMDB
	# 如果你的代码仓库或者模块是私有的，可以使用GONOSUMDB这个环境变量来设置不做校验的代码仓库
	go env -w GONOSUMDB="git.example.com/*"
	
	# GOPRIVATE 设置私有仓库地址
	# 它的作用相当于同时设置 GONOPROXY 和 GONOSUMDB
	```


## Getting Started

Create project
> 在 GOPATH 之外新建一个项目
```bash
mkdir -p ~/workspace/github/lqshow/go-mod-guide && cd ~/workspace/github/lqshow/go-mod-guide
```

Initialize project
> 在项目根目录下执行
> 初始化一个新的 module, 并创建 go.mod 文件
```bash
go mod init github.com/lqshow/go-mod-guide
```

Create go.mod

```bash
➜ cat go.mod
module github.com/lqshow/go-mod-guide

go 1.14
```

Create server.go

```go
package main

import (
  "net/http"
  "github.com/labstack/echo/v4"
  "github.com/labstack/echo/v4/middleware"
)

func main() {
  // Echo instance
  e := echo.New()

  // Middleware
  e.Use(middleware.Logger())
  e.Use(middleware.Recover())

  // Routes
  e.GET("/", hello)

  // Start server
  e.Logger.Fatal(e.Start(":1323"))
}

// Handler
func hello(c echo.Context) error {
  return c.String(http.StatusOK, "Hello, World!")
}
```

Run aplication

> 并不需要显示的导入 github.com/labstack/echo/v4，直接运行 `go run server.go` 
>
> go module 会自动检查到依赖项，并将其加入到 go.mod 中
>
> 新生成的 go.sum 中记录了完整的嵌套依赖关系集
>
> 所有依赖下载到 `$GOPATH/pkg/mod` 中

```bash
➜ go run server.go
go: finding module for package github.com/labstack/echo/v4/middleware
go: finding module for package github.com/labstack/echo/v4
go: downloading github.com/labstack/echo/v4 v4.1.17
go: downloading github.com/labstack/echo v1.4.4
go: downloading github.com/labstack/echo v3.3.10+incompatible
go: found github.com/labstack/echo/v4 in github.com/labstack/echo/v4 v4.1.17
go: downloading golang.org/x/net v0.0.0-20200822124328-c89045814202
go: downloading github.com/valyala/fasttemplate v1.2.1
go: downloading golang.org/x/crypto v0.0.0-20200820211705-5c72a883971a
go: downloading github.com/labstack/gommon v0.3.0
go: downloading github.com/mattn/go-isatty v0.0.12
go: downloading github.com/mattn/go-colorable v0.1.7
go: downloading golang.org/x/sys v0.0.0-20200826173525-f9321e4c35a6

   ____    __
  / __/___/ /  ___
 / _// __/ _ \/ _ \
/___/\__/_//_/\___/ v4.1.17
High performance, minimalist Go web framework
https://echo.labstack.com
____________________________________O/_______
                                    O\
⇨ http server started on [::]:1323
```

```bash
➜ cat go.mod
module github.com/lqshow/go-mod-guide

go 1.14

require github.com/labstack/echo/v4 v4.1.17 // indirect
```

## Tips

### replace
> 替换 require 中声明的依赖，使用另外的依赖及其版本号

#### 场景一：使用 fork 包
```bash
➜ cat go.mod
module github.com/lqshow/go-mod-guide

go 1.14

replace github.com/labstack/echo/v4 => github.com/lqshow/echo/v4 v4.1.17

require github.com/labstack/echo/v4 v4.1.17
```

#### 场景二：使用本地调试包
```bash
➜ cat go.mod
module github.com/lqshow/go-mod-guide

go 1.14

replace github.com/labstack/echo/v4 => /Users/linqiong/workspace/github/lqshow/echo

require github.com/labstack/echo/v4 v4.1.17
```

### 拉取私有库
> 假设 gitlab url: https://git.example.com/

```dockerfile
RUN git config --global --add url."ssh://git@git.example.com/".insteadOf  "https://git.example.com/"

RUN go env -w GO111MODULE=on \
	&& go env -w GOPROXY=https://goproxy.cn,direct \
	&& go env -w GOPRIVATE=git.example.com
```


### 安装依赖

> 安装 package 最先拉取最新的 release tag，如果没有打 tag，则拉取最新的 commit.

```bash
# 安装最新的 commit
go get git.example.com/foo-bar@master

# 安装匹配最新的 tag
go get git.example.com/foo-bar@latest

# 安装指定 tag
go get git.example.com/foo-bar@v1.2.3

# 安装指定 branch
go get git.example.com/foo-bar@dev_branch

# 安装指定的 commit hash
go get git.example.com/foo-bar@de8d031a

# 安装升级到最新的次要版本或者修订版本
# (x.y.z, z是修订版本号， y是次要版本号)
go get -u git.example.com

# 安装到所有依赖至最新的修订版本
go get -u=patch git.example.com
```



## Commands

| command             | desc                           |
| ------------------- | ------------------------------ |
| `go mod tidy`       | 拉取缺少的模块，清理未使用的依赖               |
| `go list -m all`    | 列出当前模块依赖的所有模块     |
| `go list -u -m all` | 列出当前模块依赖中可升级的模块 |
| `go list -m -versions git.basebit.me/enigma/enigma2-datasetx`         | 列出包的所有版本（打tag）         |
| `go clean -modcache`   | 清理所有已缓存的模块版本数据   |
| `go mod graph`   | 打印模块依赖项   |
| `go mod download`   | 下载 go.mod 文件中指明的所有依赖   |
| `go mod edit -fmt`   | 格式化配置文件   |
| `go mod edit -replace=old[@v]=new[@v]`   | 使用 replace 替换 package   |


## Package with Docker

### Containerize application

```dockerfile
# STEP 1 Build executable binary
ARG BUILD_IMAGE=golang:alpine
FROM ${BUILD_IMAGE} as builder

WORKDIR /workspace

# Install app dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy golang source code from the host
COPY ./ ./

# Get dependancies and Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o server .

# STEP 2 Build a small image
FROM alpine:3.11.0
RUN apk --no-cache add ca-certificates
WORKDIR /workspace

# Copy our static executable binary
COPY --from=builder /workspace/server .

CMD ["/workspace/server"]
```

### Build Image

```bash
➜ make build-image  
Sending build context to Docker daemon  104.4kB
Step 1/12 : ARG BUILD_IMAGE=golang:alpine
Step 2/12 : FROM ${BUILD_IMAGE} as builder
 ---> d099254f5fc3
Step 3/12 : WORKDIR /workspace
 ---> Using cache
 ---> fc7806af8051
Step 4/12 : COPY go.mod go.sum ./
 ---> Using cache
 ---> 837387da9d88
Step 5/12 : RUN go mod download
 ---> Using cache
 ---> 124b7c88c6d6
Step 6/12 : COPY ./ ./
 ---> 1dad63bd101f
Step 7/12 : RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o server .
 ---> Running in 54c687eb25f1
Removing intermediate container 54c687eb25f1
 ---> 11e1e5571df9
Step 8/12 : FROM alpine:3.11.0
 ---> c85b8f829d1f
Step 9/12 : RUN apk --no-cache add ca-certificates
 ---> Using cache
 ---> 6b41d14c62bd
Step 10/12 : WORKDIR /workspace
 ---> Using cache
 ---> 1127ed5278fa
Step 11/12 : COPY --from=builder /workspace/server .
 ---> Using cache
 ---> 092a4d124f04
Step 12/12 : CMD ["/workspace/server"]
 ---> Using cache
 ---> f712f232359e
Successfully built f712f232359e
Successfully tagged lqshow/go-mod-guide:d530b4e
```
### Run Container
```bash
➜ make run-container

   ____    __
  / __/___/ /  ___
 / _// __/ _ \/ _ \
/___/\__/_//_/\___/ v4.1.17
High performance, minimalist Go web framework
https://echo.labstack.com
____________________________________O/_______
                                    O\
⇨ http server started on [::]:1323
```


## Referene

- [Using Go Modules](https://blog.golang.org/using-go-modules)
- [Go Modules](https://github.com/golang/go/wiki/Modules)
- [Introduction to Go Modules](https://roberto.selbach.ca/intro-to-go-modules/)
- [Proposal: Secure the Public Go Module Ecosystem](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)
- [athens](https://github.com/gomods/athens)
