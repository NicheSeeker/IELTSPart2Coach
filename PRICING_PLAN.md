# IELTS Part 2 Coach — 定价方案

## 一、市场调研摘要

### 竞品定价对比

| App | 模式 | 价格 |
|-----|------|------|
| IELTSpeaking | 买断 | $99.99 |
| IELTS Prep App (TalkFace AI) | 买断 | $99.99 |
| IELTS Speaking Prep 2026 | 订阅 | $1.99/月 · $12.99/年 |
| IELTS Speaking Assistant | 订阅 | $9.99/月 · $29.99/年 |

### AI 口语练习类 App（更广参考）

| App | 买断价 |
|-----|-------|
| Phrase AI: Speak & Learn | $29.99 |
| Speako: AI for Public Speaking | $69.99/年 |
| Loora AI | $59.99–$119.99/年 |

### 市场数据（2025）

- 教育类 App 中位年订阅价：**$44.99**
- 买断转化率：**8–12%**（高于订阅的 2–5%）
- IELTS 市场规模：$15.3 亿美元，年增长 8.5%，亚太占 42%

---

## 二、定价决策

### 模式：付费下载（Paid App）

**价格：$6.99（一次性买断）**

| 维度 | 分析 |
|------|------|
| 竞争优势 | 竞品 $29.99–$99.99，$6.99 门槛极低 |
| 用户心理 | 约等于一杯咖啡，IELTS 考生支付意愿强 |
| 价值对比 | 传统家教 $30–80/小时，$6.99 可无限练习 |
| 实现成本 | 无需 StoreKit 代码，仅改 App Store Connect |

### 为什么选择"付费下载"而非"免费+IAP"

- 更简单：无需 StoreKit 代码、无需 Paywall UI
- 无摩擦：用户下载即拥有完整功能，无中途拦截
- 用户信任感更高：一次付清，不存在后续订阅扣费担忧

---

## 三、执行步骤

### Step 1：App Store Connect 改价（约 10 分钟）

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择 **IELTS Part 2 Coach** → **Pricing and Availability**
3. 将价格从 Free 改为 **Tier 6（$6.99 USD）**
4. 保存即生效，**无需提交新版本，无需审核**

全球对应参考价：

| 地区 | 价格 |
|------|------|
| 美国 | $6.99 |
| 中国大陆 | ¥45 |
| 香港 | HK$58 |
| 英国 | £5.99 |
| 澳大利亚 | A$10.99 |

> 已下载的免费版用户不受影响，可继续使用。

---

### Step 2：App Store 产品页优化（约 1–2 小时）

产品页是决定付费转化率的最关键因素。

**建议 Subtitle（30字内）**
```
AI-Powered IELTS Speaking Coach
```

**Description 核心要点**
- 一次买断，终身使用
- AI 即时反馈：流利度、词汇、语法、发音四维评分
- 无需网络账户，录音本地存储，完全隐私
- 仿真 IELTS Part 2 考试流程（60s 准备 + 120s 作答）

**截图建议（6 张）**

| 序号 | 内容 | 要点 |
|------|------|------|
| 1 | 主题卡 + Start 按钮 | 第一印象，简洁美观 |
| 2 | 录音界面（波形 + 计时环）| 展示核心功能 |
| 3 | AI 反馈摘要（summary + tip）| 核心价值 |
| 4 | Band Score 四环 | 专业感，量化结果 |
| 5 | 练习历史列表 | 长期使用价值 |
| 6 | 进度趋势 / 连续打卡 | 习惯养成动力 |

---

### Step 3：后端每日限制评估

| 功能 | 当前限制 | 建议 |
|------|---------|------|
| AI 语音分析 | 10次/天/设备 | 保持（IELTS 考生够用）|
| AI 题目生成 | 包含在限制内 | 可考虑单独放宽 |

结论：10次/天对付费用户合理，暂不调整后端。

---

### Step 4：可选代码改动（锦上添花）

以下不影响定价，但提升付费用户体验：

**SettingsView.swift — About 区块添加购买状态**
```swift
// About 区块增加一行
Label("Lifetime Access Unlocked", systemImage: "checkmark.seal.fill")
    .foregroundStyle(.green)
```

**作用**：让用户有"拥有感"，减少后悔情绪。

---

## 四、不需要做的事

| 项目 | 原因 |
|------|------|
| StoreKit 框架集成 | 付费下载无需 IAP |
| Paywall UI | 下载即解锁全部功能 |
| Receipt Validation | App Store 自动处理 |
| Restore Purchases 按钮 | 付费 App 由 App Store 原生支持 |
| 后端验证逻辑 | 不需要验证购买状态 |

---

## 五、验证方法

1. App Store Connect 保存后，搜索 app 确认显示 **$6.99**
2. 用沙盒 Apple ID 测试购买流程（App Store Connect → Users and Access → Sandbox Testers）
3. 确认已购用户重新安装后无需再次付费（App Store 原生保障）

---

## 六、后续增长策略（可选）

- **TestFlight**：发布前邀请小圈子测试，收集口碑
- **App Store 评分**：代码已有 `AppReviewManager`，适时弹出评分请求
- **冷启动期临时降价**：$4.99，拉动早期下载量和评论数
- **限时优惠**：App Store 支持 Introductory Offer，可设置限时折扣
