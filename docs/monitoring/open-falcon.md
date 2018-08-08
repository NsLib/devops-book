# Open Falcon

## 简介

Open-Falcon是小米自主研发的一款监控系统，并与2015年5月宣布开源。其凭借配置简单、高性能、稳定可靠、易于扩展等特性，迅速占领了国内监控系统市场，一举打破了国外对监控系统领域的垄断，并且在亚太地区影响力不断扩大（笔者就职过的小米公司和美团点评均对Open-Falcon做了大量二次开发工作）。

## 特性

* 高度组件化，极其强大的水平扩展能力（几乎所有组件都可以水平扩展）
* 监控节点自动发现
* 支持用户主动上报数据(HTTP接口)
* 支持用户自定义插件
* 内置UIC支持
* 简单的告警合并
* 支持用户自定义screen，方便日常巡检

## 架构

![Open-Falcon Architecture](/images/open-falcon-architecture.png)

## 痛点

> 之后会给出大部分痛点的解决方案。

* 由于没有Naming服务，需要交互的组件都是直接将IP和端口写在配置文件中，管理起来颇为不便。
* 无法基于环比做告警策略（Judge组件有个Remain参数，控制缓存在内存里面某个指标的个数，官方默认配置是11，也就是可以向前查找10个点）
* 各种策略、模板下发实现机制是定期同步，因此很多修改无法即时生效。
* 告警合并、告警升级策略有滞后，无法第一时间通知到用户。
* 缺乏良好权限控制。

## 参考资料

* [Open-Falcon v0.2](http://book.open-falcon.org/zh_0_2/)
* [Open-Falcon GitHub Org](https://github.com/open-falcon)
* [Mt-Falcon——Open-Falcon在美团点评的应用与实践](https://tech.meituan.com/Mt_Falcon_Monitoring_System.html)
* [基于Falcon的滴滴内部监控系统](https://mp.weixin.qq.com/s/t0LNdHQg7lv-_9nLlPHC5Q)
