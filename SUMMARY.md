# Summary

## 前言

[序言](README.md)

## 平台篇


* [监控告警](docs/monitoring/index.md)
    * [Open-Falcon](docs/monitoring/open-falcon.md)
    * [Open-Falcon源码剖析01](docs/monitoring/open-falcon/open-falcon-source-01.md)
* 待整理
    * 服务树
    * [权限系统](docs/IAM.md)
    * 服务器实时监控
    * CMDB
    * 审计日志
    * 排班管理
    * 工单管理
    * 工作流引擎
    * 全局状态看板
    * 变更管理
    * 分布式定时任务
* Iaas、PaaS、SaaS
    * Heroku
    * Cloud Foundry
    * OpenStack
    * Kubernetes
    * Mesos
    * Deis
    * Docker
    * AWS
    * GCE
    * 阿里云
    * 腾讯云
    * 12-Factor
    * Reaction宣言
    * SDN
* CICD
    * Jenkins
    * Gitlab CI
    * Travis CI
    * Circle CI
    * flow.ci
    * gocd
    * drone (个人没用过, 有兴趣研究)
    * strider (早期版本代码、安全性都不太好，待跟进)
* 故障
    * 故障自愈 (StackStorm/st2 是个不错的思路)
* 效率工具
* XX管理
    * 技术管理
    * 资源管理
    * 发布管理
    * 流程管理
    * 知识管理
    * 资产管理
    * 成本管理
    * 风险管理
    * 安全管理
    * 值班管理
    * 问题管理
    * 变更管理
    * 时间管理
    * 配置管理
    * 容量管理
    * 效率管理
    * 性能管理
    * 可用性管理
    * 报表管理

## 运维篇

* 大型抢购活动准备
    * 容量
    * 压测
    * 灾备
    * 预案
    * 值班
    * 监控
    * 混合云实践
* 服务
    * 故障分级
    * 服务分级
    * SLA
    * SOA
    * Service Mesh
* 接入
    * Nginx (源码级讲解)
    * LVS  (准备看看源码, 时间允许的话, 源码级讲解)
    * HAProxy
    * Keepalived
* 计算
    * Kubernetes
    * OpenStack
    * Deis
    * Mesos
    * Docker
* 存储
    * Redis
    * MySQL
    * PostgreSQL
    * TiDB
    * 对象存储 (可能讲 OpenStack Swift)
    * Ceph (个人了解不多, 可能会请人来写)
* 网络
    * flannel (源码级讲解)
    * ingress-nginx (源码级讲解)

* 监控告警
    * Nagios
    * Cacti
    * Zabbix
    * Open-Falcon (源码级讲解)
    * Prometheus (源码级讲解)
    * 监控的定义与价值
    * 监控体系的设计与实现(分层)
    * 域名监控、URL监控、连通性监控、内容监控、劫持监控、舆情监控、网络监控、异常崩溃监控……
    * 告警合并、告警升级、Ack/Resolve、告警屏蔽、告警禁用、告警分析、告警分类、告警途径、告警关联

* 日志
    * ELF
    * filebeat

* 管理工具
    * SaltStack
    * Ansible
    * Puppet
    * terraform (最接近IAC(Infrastructure as Code)的方案)
    * pssh、pdsh、mussh
* 安全
    * WAF
    * 跳板机
    * 动态令牌
    * 操作审计
    * 敏感信息扫描
    * root权限管理
    * 事前(主动防御系统)、日常安全扫描、事后分析、数据过滤

## 开发篇

* 工程化
    * 前端工程化
    * 后端工程化
    * 微服务
    * OpenAPI架构
    * 文档系统
