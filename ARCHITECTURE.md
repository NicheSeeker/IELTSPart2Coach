# IELTS Part 2 Coach — 架构图（回忆版）

> 目标：用一张图把「端上做什么 / 后端做什么 / 第三方在哪里」说清楚，方便你两个月后快速找回上下文。

```mermaid
flowchart LR
  %% ===== iOS App =====
  subgraph IOS[iOS App（SwiftUI）]
    UI[Views<br/>QuestionCard / Feedback / History / Settings]
    VM[RecordingViewModel<br/>状态机: idle→preparing→recording→finished→analyzing]

    AR[AudioRecorder<br/>WAV(PCM 44.1kHz) + waveform]
    AP[AudioPlayer]
    SR[SpeechRecognitionService<br/>可选转写(分段≤50s)]
    GM[GeminiService<br/>HTTP Client + JSON 解析]
    NM[NotificationManager<br/>本地通知(3-day reminder)]
    DM[DataManager<br/>JSON 文件持久化(替代 SwiftData)]
    KC[(Keychain<br/>device_id<br/>openrouter_api_key* )]
    FS[(On-device Files<br/>/Documents/Recordings/*.wav<br/>/Documents/Persistence/*.json)]
    TJ[(topics.json<br/>离线题库)]

    UI --> VM
    VM --> AR
    VM --> AP
    VM --> SR
    VM --> GM
    VM --> NM
    VM --> DM
    GM --> KC
    DM --> FS
    VM --> TJ
  end

  %% ===== Optional Apple Speech =====
  subgraph APPLE[Apple Services（可选）]
    ASR[Apple Speech Recognition API]
  end
  SR -- audio file --> ASR
  ASR -- transcript --> SR

  %% ===== Backend =====
  subgraph CF[Cloudflare Workers（你的后端代理）]
    W[Worker API<br/>/generate-topic<br/>/analyze-speech]
    KV[(Workers KV<br/>按 device_id 的每日计数/限流)]
    W --> KV
  end

  %% ===== AI Provider =====
  subgraph AI[第三方 AI]
    OR[OpenRouter API<br/>chat/completions]
    G[Google Gemini 2.5 Flash]
    OR --> G
  end

  %% ===== Request Flows =====
  GM -- HTTPS POST<br/>X-Device-ID + JSON(prompt) --> W
  GM -- HTTPS POST<br/>X-Device-ID + JSON(base64 audio) --> W
  W -- server-side fetch<br/>OPENROUTER_API_KEY(env) --> OR
  OR -- response(JSON) --> W
  W -- response(JSON) --> GM
  GM --> VM --> UI
```

## 你可能最想回忆的 8 件事

1. **主入口**：`IELTSPart2CoachApp → ContentView → QuestionCardView`（核心界面都围绕 `RecordingViewModel` 转）。
2. **录音流**：`AudioSessionManager` 负责 session；`AudioRecorder` 只管录 WAV + waveform；录完会把临时文件移动到 `Documents/Recordings/`。
3. **状态机**：`RecordingViewModel` 明确区分准备/录音/分析阶段；分析阶段还细分 `encoding/uploading/analyzing/preparing` 给 UI 做“呼吸感”反馈。
4. **持久化策略变更**：`SwiftData` 被禁用（为避免首启 schema building 卡死），改用 `DataManager` 写入轻量 JSON：`sessions.json / topicHistory.json / userProgress.json`。
5. **AI 两条链路**：
   - `generate-topic`：生成新题（会避开最近 5 个题目；失败就 fallback 到 `topics.json`）。
   - `analyze-speech`：把 audio base64 发送出去，拿回结构化 JSON（4 项 IELTS 分数 + summary/actionTip/quote）。
6. **后端定位**：App **只打 Cloudflare Worker**；Worker 再转发 OpenRouter/Gemini，并用 KV 做 **10 次/天/设备** 的限流（`X-Device-ID`）。
7. **设备标识**：`device_id` 懒生成并存 Keychain（用于限流/防滥用；不是登录系统）。
8. **转写是可选功能**：开启后走 `SpeechRecognitionService` → Apple Speech（目前强制 server-based 以提升长音频质量），结果只落本地。

> `openrouter_api_key*`：代码里仍保留了“端上存 OpenRouter Key”的 UI/Keychain 逻辑，但当前网络请求走 Worker 代理时不会把它作为请求头发送（更多像历史遗留/回滚预案）。

