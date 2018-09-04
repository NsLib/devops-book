# Open-Falcon源码剖析——Alarm模块

## 项目结构

```
.
├── api
│   ├── links.go
│   ├── portal.go
│   ├── portal_test.go
│   ├── uic.go
│   └── uic_test.go
├── cfg.example.json
├── control
├── cron
│   ├── builder.go
│   ├── callback.go
│   ├── combiner.go
│   ├── event_cleaner.go
│   ├── event_consumer.go
│   ├── event_reader.go
│   ├── im_sender.go
│   ├── init_sender.go
│   ├── mail_sender.go
│   ├── model.go
│   └── sms_sender.go
├── g
│   ├── cfg.go
│   ├── eventdto.go
│   ├── g.go
│   ├── logger.go
│   └── redis.go
├── http
│   ├── controller.go
│   └── http.go
├── main.go
├── model
│   ├── database.go
│   ├── event
│   │   ├── event.go
│   │   └── event_operation.go
│   ├── im.go
│   ├── mail.go
│   └── sms.go
└── redi
    ├── msg_reader.go
    └── msg_writer.go
```

## 剖析

### 启动

```go
func main() {
	// 解析配置文件
	g.ParseConfig(*cfg)

	// 初始化redis, db, 短信/邮件/IM
	g.InitRedisConnPool()
	model.InitDatabase()
	cron.InitSenderWorker()

	// HTTP接口: /version, /health, /workdir
	go http.Start()
	go cron.ReadHighEvent()
	go cron.ReadLowEvent()

	// 短信、邮件、IM告警合并
	go cron.CombineSms()
	go cron.CombineMail()
	go cron.CombineIM()

	// 这几个任务真正处理发送逻辑
	go cron.ConsumeIM()
	go cron.ConsumeSms()
	go cron.ConsumeMail()

	// 定期清理DB中的信息
	go cron.CleanExpiredEvent()

	// 防止主线程退出
	select {}
}
```

上面的这些goroutine, 基本上都是无限的for循环+sleep, 后面会一一进行分析.

### HTTP接口

```go
func Start() {
	r := gin.Default()
	r.GET("/version", Version)
	r.GET("/health", Health)
	r.GET("/workdir", Workdir)
	r.Run(addr)
}
```

```go
func Version(c *gin.Context) {
	c.String(200, g.VERSION)
}

func Health(c *gin.Context) {
	c.String(200, "ok")
}

func Workdir(c *gin.Context) {
	c.String(200, file.SelfDir())
}
```

* `/version`: 获取alarm agent版本信息
* `/health`: 健康检查, 用于检测alarm agent是否存活
* `/workdir`: 获取alarm agent路径

### 高优先级报警事件处理

```go
go cron.ReadHighEvent()
```

```go
// 轮询+sleep
func ReadHighEvent() {
	for {
		event, err := popEvent(queues)
		if err != nil {
			time.Sleep(time.Second)
			continue
		}
		consume(event, true)
	}
}

func consume(event *cmodel.Event, isHigh bool) {
	actionId := event.ActionId()
	if actionId <= 0 {
		return
	}

	action := api.GetAction(actionId)
	if action == nil {
		return
	}

	// 报警HTTP回调接口
	if action.Callback == 1 {
		HandleCallback(event, action)
	}

	// 高优先级和低优先级分开处理, 防止低优先级报警堆积, 进而影响高优先级报警
	if isHigh {
		consumeHighEvents(event, action)
	} else {
		consumeLowEvents(event, action)
	}
}

// 高优先级的不做报警合并
func consumeHighEvents(event *cmodel.Event, action *api.Action) {
	if action.Uic == "" {
		return
	}

	// 获取报警联系人相关信息
	phones, mails, ims := api.ParseTeams(action.Uic)

	// 生成报警内容
	smsContent := GenerateSmsContent(event)
	mailContent := GenerateMailContent(event)
	imContent := GenerateIMContent(event)

	// <=P2 才发送短信
	if event.Priority() < 3 {
		redi.WriteSms(phones, smsContent)
	}

	// 这里将报警信息写入redis中, 发送逻辑在 cron.ConsumeIM() / cron.ConsumeSms() / cron.ConsumeMail()
	redi.WriteIM(ims, imContent)
	redi.WriteMail(mails, smsContent, mailContent)
}
```

### 低优先级报警事件处理

低优先级报警事件处理逻辑与高优先级报警事件处理逻辑相似度90%以上, 请自行阅读源码
