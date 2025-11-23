# 📋 Cloudflare Workers Backend Setup Guide

**用户操作清单** - 后端迁移方案所需的 Cloudflare 配置步骤

---

## ⏱️ 预计时间: 30-45 分钟

---

## 📦 前置准备

### 必需材料

- [ ] Cloudflare 账号（免费）
- [ ] OpenRouter API Key (`sk-or-v1-...`)
- [ ] 信用卡（Cloudflare Workers 验证，免费套餐 **不收费**）
- [ ] 命令行工具: `npm` 或 `pnpm`

### 可选材料

- [ ] 自定义域名（可选，用于 `https://api.yourdomain.com` 代替 `*.workers.dev`）

---

## 📝 Step 1: 注册 Cloudflare 账号

### 1.1 创建账号

1. 访问 [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. 填写邮箱和密码
3. 验证邮箱（检查收件箱/垃圾邮件）

### 1.2 验证信用卡（免费套餐不收费）

1. 登录 Cloudflare Dashboard
2. 导航到 **Account** → **Billing**
3. 添加支付方式（Visa/Mastercard）
4. **注意**: Workers 免费套餐每天 100,000 次请求，本项目远低于此限制

**验证完成标志**: Dashboard 右上角账户状态显示 ✅ Verified

---

## 🔨 Step 2: 安装 Wrangler CLI

Wrangler 是 Cloudflare Workers 的官方 CLI 工具。

### 2.1 安装 Wrangler（推荐全局安装）

```bash
# 使用 npm
npm install -g wrangler

# 或使用 pnpm（更快）
pnpm add -g wrangler

# 验证安装
wrangler --version
# 预期输出: ⛅️ wrangler 3.x.x
```

### 2.2 登录 Cloudflare

```bash
wrangler login
```

**操作**:
1. 命令行会打开浏览器
2. 授权 Wrangler 访问你的 Cloudflare 账号
3. 回到命令行，确认看到 "Successfully logged in"

---

## 📂 Step 3: 创建 Worker 项目

### 3.1 创建项目目录

```bash
# 在任意位置创建项目文件夹
mkdir ielts-backend
cd ielts-backend

# 初始化 npm 项目
npm init -y
```

### 3.2 创建 Worker 代码文件

**创建 `src/index.js`**:

```bash
mkdir src
touch src/index.js
```

**复制以下完整代码到 `src/index.js`**:

```javascript
const OPENROUTER_ENDPOINT = 'https://openrouter.ai/api/v1/chat/completions';
const MODEL = 'google/gemini-2.5-flash';
const DAILY_LIMIT = 10;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Device-ID',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      if (url.pathname === '/generate-topic' && request.method === 'POST') {
        return await handleGenerateTopic(request, env, corsHeaders);
      }
      if (url.pathname === '/analyze-speech' && request.method === 'POST') {
        return await handleAnalyzeSpeech(request, env, corsHeaders);
      }
      return jsonResponse({ error: 'Not found' }, 404, corsHeaders);
    } catch (error) {
      console.error(error);
      return jsonResponse({ error: error.message }, 500, corsHeaders);
    }
  },
};

async function handleGenerateTopic(request, env, corsHeaders) {
  const deviceID = request.headers.get('X-Device-ID');
  if (!deviceID) {
    return jsonResponse({ error: 'Missing device ID' }, 400, corsHeaders);
  }

  // Check rate limit
  const allowed = await checkRateLimit(deviceID, env);
  if (!allowed) {
    return jsonResponse({ error: 'dailyLimitReached' }, 429, corsHeaders);
  }

  // Parse request body
  const body = await request.json();

  // Forward to OpenRouter (return response as-is)
  const openrouterResponse = await callOpenRouter(body.messages, env);

  return new Response(JSON.stringify(openrouterResponse), {
    status: 200,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}

async function handleAnalyzeSpeech(request, env, corsHeaders) {
  const deviceID = request.headers.get('X-Device-ID');
  if (!deviceID) {
    return jsonResponse({ error: 'Missing device ID' }, 400, corsHeaders);
  }

  // Check rate limit
  const allowed = await checkRateLimit(deviceID, env);
  if (!allowed) {
    return jsonResponse({ error: 'dailyLimitReached' }, 429, corsHeaders);
  }

  // Parse request body
  const body = await request.json();

  // Forward to OpenRouter (return response as-is)
  const openrouterResponse = await callOpenRouter(body.messages, env);

  return new Response(JSON.stringify(openrouterResponse), {
    status: 200,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });
}

async function checkRateLimit(deviceID, env) {
  const today = new Date().toISOString().split('T')[0];
  const key = `${deviceID}:${today}`;
  const count = parseInt((await env.USAGE.get(key)) || '0');

  if (count >= DAILY_LIMIT) {
    return false;
  }

  // Increment count with 24h expiration
  await env.USAGE.put(key, (count + 1).toString(), { expirationTtl: 86400 });
  return true;
}

async function callOpenRouter(messages, env) {
  const response = await fetch(OPENROUTER_ENDPOINT, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'X-Title': 'IELTSPart2Coach',
      'HTTP-Referer': 'https://com.Charlie.IELTSPart2Coach',
    },
    body: JSON.stringify({
      model: MODEL,
      response_format: { type: 'json_object' },
      messages: messages,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenRouter API error: ${response.status}`);
  }

  return await response.json();
}

function jsonResponse(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...headers },
  });
}
```

---

## 🔧 Step 4: 创建 `wrangler.toml` 配置文件

**创建 `wrangler.toml` 在项目根目录**:

```toml
name = "ielts-api"
main = "src/index.js"
compatibility_date = "2025-01-15"

[[kv_namespaces]]
binding = "USAGE"
id = "PLACEHOLDER_KV_ID"  # ← 稍后替换
preview_id = "PLACEHOLDER_KV_ID"  # ← 稍后替换
```

**注意**: `PLACEHOLDER_KV_ID` 将在 Step 5 中替换为真实的 KV namespace ID。

---

## 💾 Step 5: 创建 KV Namespace（关键存储）

KV namespace 用于存储每日请求计数（rate limiting）。

### 5.1 创建 KV Namespace

```bash
wrangler kv:namespace create USAGE
```

**预期输出**:
```
🌀 Creating namespace with title "ielts-api-USAGE"
✨ Success!
Add the following to your wrangler.toml:

[[kv_namespaces]]
binding = "USAGE"
id = "abc123xyz456abc123xyz456abc12345"
```

### 5.2 复制 KV Namespace ID

从输出中复制 `id = "..."` 的值（例如 `abc123xyz456abc123xyz456abc12345`）

### 5.3 创建 Preview KV Namespace（用于本地测试）

```bash
wrangler kv:namespace create USAGE --preview
```

**预期输出**:
```
Add the following to your wrangler.toml:

[[kv_namespaces]]
binding = "USAGE"
preview_id = "def456uvw789def456uvw789def45678"
```

复制 `preview_id = "..."` 的值。

### 5.4 更新 `wrangler.toml`

用真实 ID 替换 `PLACEHOLDER_KV_ID`:

```toml
[[kv_namespaces]]
binding = "USAGE"
id = "abc123xyz456abc123xyz456abc12345"  # ← 你的真实 KV ID
preview_id = "def456uvw789def456uvw789def45678"  # ← 你的真实 Preview KV ID
```

---

## 🔐 Step 6: 配置 OpenRouter API Key（Secret）

**⚠️ 重要**: API Key 作为加密 Secret 存储，**不会**出现在代码或配置文件中。

### 6.1 设置 API Key Secret

```bash
wrangler secret put OPENROUTER_API_KEY
```

**操作**:
1. 命令行提示: `Enter a secret value:`
2. 粘贴你的 OpenRouter API Key（例如 `sk-or-v1-abc123...`）
3. 按 Enter 确认

**预期输出**:
```
✨ Success! Uploaded secret OPENROUTER_API_KEY
```

### 6.2 验证 Secret（可选）

```bash
wrangler secret list
```

**预期输出**:
```
[
  {
    "name": "OPENROUTER_API_KEY",
    "type": "secret_text"
  }
]
```

**注意**: Secret 值本身无法查看（加密存储），这是正常的。

---

## 🚀 Step 7: 本地测试（可选但推荐）

### 7.1 启动本地开发服务器

```bash
wrangler dev
```

**预期输出**:
```
⎔ Starting local server...
[wrangler:inf] Ready on http://localhost:8787
```

### 7.2 测试 Topic Generation Endpoint

**打开新终端窗口**，运行:

```bash
curl -X POST http://localhost:8787/generate-topic \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: test-device-123" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "You are an IELTS Speaking Part 2 topic generator. Generate ONE topic in strict JSON format: {\"title\": \"Describe...\", \"prompts\": [\"...\", \"...\", \"...\"]}"
      }
    ]
  }'
```

**预期响应** (简化版):
```json
{
  "choices": [
    {
      "message": {
        "content": "{\"title\":\"Describe a memorable journey\",\"prompts\":[\"Where you went\",\"What you did\",\"Why it was memorable\"]}"
      }
    }
  ]
}
```

**如果成功**: 看到包含 `title` 和 `prompts` 的 JSON → ✅ Worker 正常工作！

### 7.3 测试 Rate Limiting（连续请求 11 次）

```bash
# 运行 11 次相同请求
for i in {1..11}; do
  echo "Request $i:"
  curl -X POST http://localhost:8787/generate-topic \
    -H "Content-Type: application/json" \
    -H "X-Device-ID: test-device-456" \
    -d '{"messages":[{"role":"user","content":"Test"}]}'
  echo ""
done
```

**预期行为**:
- 前 10 次: 返回正常响应
- 第 11 次: 返回 `{"error":"dailyLimitReached"}` + HTTP 429

**如果成功**: ✅ Rate limiting 工作正常！

### 7.4 停止本地服务器

按 `Ctrl + C` 停止 `wrangler dev`

---

## 🌐 Step 8: 部署到生产环境

### 8.1 部署 Worker

```bash
wrangler deploy
```

**预期输出**:
```
Total Upload: xx.xx KiB / gzip: xx.xx KiB
Uploaded ielts-api (x.xx sec)
Published ielts-api (x.xx sec)
  https://ielts-api.YOUR-USERNAME.workers.dev
Current Deployment ID: abc123-def456-ghi789
```

### 8.2 记录 Worker URL

从输出中复制 Worker URL，例如:
```
https://ielts-api.charlie.workers.dev
```

**重要**: 你需要用这个 URL 替换 iOS 项目中的 `YOUR-WORKER-NAME`。

### 8.3 测试生产环境 Endpoint

```bash
curl -X POST https://ielts-api.YOUR-USERNAME.workers.dev/generate-topic \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: prod-test-001" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": "You are an IELTS Speaking Part 2 topic generator. Generate ONE topic in strict JSON format: {\"title\": \"Describe...\", \"prompts\": [\"...\", \"...\", \"...\"]}"
      }
    ]
  }'
```

**如果成功**: 返回有效的 Topic JSON → ✅ 生产部署成功！

---

## 📲 Step 9: 更新 iOS 项目配置

### 9.1 修改 `GeminiService.swift`

打开文件:
```
IELTSPart2Coach/IELTSPart2Coach/Services/GeminiService.swift
```

找到 Line 57（或附近）:
```swift
private let baseURL = "https://ielts-api.YOUR-WORKER-NAME.workers.dev"
```

**替换 `YOUR-WORKER-NAME` 为你的真实子域名**，例如:
```swift
private let baseURL = "https://ielts-api.charlie.workers.dev"
```

### 9.2 保存并构建 iOS 项目

```bash
# 在 Xcode 中按 Cmd + B 构建项目
# 或使用命令行
xcodebuild -scheme IELTSPart2Coach \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

**如果构建成功**: ✅ iOS 项目配置正确！

---

## ✅ Step 10: 完整端到端测试

### 10.1 iOS App 测试清单

**在 iPhone 模拟器或真机上运行 app**:

1. **首次启动（Device ID 生成）**:
   - [ ] App 启动成功
   - [ ] Xcode Console 显示: `🆔 Generated new device ID: ...`
   - [ ] 无崩溃或错误

2. **Topic Generation 测试**:
   - [ ] 点击 "New Topic" 按钮
   - [ ] 新题目出现在 QuestionCardView
   - [ ] Xcode Console 显示: `✨ AI Topic Generated: ...`
   - [ ] 无网络错误

3. **Audio Analysis 测试**:
   - [ ] 录制 30 秒音频
   - [ ] 点击 "Get AI feedback"
   - [ ] 看到分析阶段进度（Encoding → Uploading → Analyzing）
   - [ ] FeedbackView 正确显示（bands, summary, tip, quote）
   - [ ] 无 API 错误

4. **Daily Limit 测试**:
   - [ ] 连续生成 10 个新题目（或 10 次 AI feedback）
   - [ ] 第 11 次请求显示错误: "That's all for today. Come back tomorrow..."
   - [ ] 错误提示友好，不崩溃

5. **Network Error 测试**:
   - [ ] 开启飞行模式
   - [ ] 尝试生成题目
   - [ ] 错误提示: "Network connection failed. Please check your internet."
   - [ ] 关闭飞行模式，重试成功

### 10.2 Cloudflare Dashboard 验证

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 导航到 **Workers & Pages** → **ielts-api**
3. 点击 **Metrics** 标签
4. **预期看到**:
   - **Requests**: 图表显示请求量（每次 iOS 调用都会记录）
   - **Success Rate**: 应接近 100%（绿色）
   - **Errors**: 应接近 0（红色为 0 最佳）

5. 点击 **KV** 标签
6. 查看 KV namespace `USAGE`
7. **预期看到**:
   - Keys 列表包含: `<device-id>:2025-11-22` 格式的条目
   - Value: 数字（1-10，表示今日请求次数）

---

## 🎉 完成确认清单

全部完成后，勾选以下项目:

- [ ] ✅ Cloudflare 账号已创建并验证
- [ ] ✅ Wrangler CLI 已安装并登录
- [ ] ✅ Worker 代码文件 `src/index.js` 已创建
- [ ] ✅ `wrangler.toml` 配置文件已正确填写
- [ ] ✅ KV namespace 已创建（production + preview）
- [ ] ✅ OpenRouter API Key 已设置为 Secret
- [ ] ✅ 本地测试通过（topic generation + rate limiting）
- [ ] ✅ Worker 已部署到生产环境
- [ ] ✅ iOS 项目 `baseURL` 已更新为真实 Worker URL
- [ ] ✅ iOS App 端到端测试通过（所有 5 项测试）
- [ ] ✅ Cloudflare Dashboard 显示正常请求量

---

## 🛠️ 常见问题排查

### 问题 1: `wrangler login` 浏览器未打开

**症状**: 运行 `wrangler login` 后无反应

**解决方案**:
```bash
# 手动获取登录链接
wrangler login --browser=false
```
复制输出的 URL，手动在浏览器打开。

---

### 问题 2: Worker 部署后返回 500 错误

**症状**: iOS App 调用 Worker 返回 "Analysis failed (code: 500)"

**排查步骤**:

1. 检查 Worker 日志:
   ```bash
   wrangler tail
   ```
   在 iOS App 中重试请求，查看实时日志输出。

2. 常见原因:
   - ❌ OPENROUTER_API_KEY Secret 未设置 → 重新运行 `wrangler secret put`
   - ❌ KV namespace ID 错误 → 检查 `wrangler.toml` 中的 `id` 值
   - ❌ OpenRouter API Key 无效 → 验证 key 格式为 `sk-or-v1-...`

---

### 问题 3: iOS App 显示 "dailyLimitReached" 但实际未达 10 次

**症状**: 明明只请求了 3 次，却提示达到每日限制

**原因**: KV 存储可能有旧数据

**解决方案**:
```bash
# 删除特定设备的限流记录
wrangler kv:key delete "<device-id>:2025-11-22" --namespace-id=abc123...

# 或删除所有 keys（慎用）
wrangler kv:key list --namespace-id=abc123...
# 手动删除每个 key
```

---

### 问题 4: iOS App 无法连接到 Worker（网络错误）

**症状**: "Network connection failed" 但网络正常

**排查步骤**:

1. 验证 Worker URL 是否正确:
   ```bash
   curl https://ielts-api.YOUR-USERNAME.workers.dev/generate-topic
   ```
   应返回 404 错误（正常，说明 Worker 在线）

2. 检查 iOS 代码中的 URL:
   - 打开 `GeminiService.swift`
   - 确认 `baseURL` 没有拼写错误
   - 确认没有多余的 `/` 或空格

3. 检查 CORS headers:
   - Worker 代码中 `corsHeaders` 必须包含 `Access-Control-Allow-Origin: *`

---

### 问题 5: Xcode 构建失败（编译错误）

**症状**: 修改 `GeminiService.swift` 后无法构建

**常见错误**:

1. **字符串未闭合**: 检查 `baseURL` 的引号是否配对
2. **行号对不上**: 代码文件已被修改，行号可能变化
3. **缺少 import**: 确保文件顶部有 `import Foundation`

**解决方案**:
```bash
# 清理构建缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 重新构建
xcodebuild clean build -scheme IELTSPart2Coach
```

---

## 📞 需要帮助？

如果遇到其他问题，提供以下信息可加速排查：

1. **Worker 日志** (`wrangler tail` 输出)
2. **iOS Console 日志** (Xcode → Window → Devices and Simulators → Open Console)
3. **Cloudflare Dashboard Metrics** (截图)
4. **具体错误信息** (完整文本，不要截图)

---

**配置完成时间**: _________
**Worker URL**: _________
**首次测试成功**: ☑️ / ☐
