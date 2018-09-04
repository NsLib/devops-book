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
