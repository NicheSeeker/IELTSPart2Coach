# 🚀 IELTS Part 2 Coach: 统一后端迁移实施计划

**版本**: 1.0
**日期**: 2025-11-22
**预计工时**: 15-20 小时
**状态**: 等待执行

---

## 📋 执行决策确认

基于您的选择，本实施计划将按以下策略执行：

| 决策点 | 选择 | 实施细节 |
|--------|------|----------|
| **后端部署** | B | 提供 Cloudflare Workers 完整注册指南 + 部署教程 |
| **API Key 迁移** | A | 强制迁移，删除所有 BYOK 相关代码和 UI |
| **每日限流** | A | 10 次/天/设备，通过 KV store 追踪 |
| **错误提示语** | A (定制化) | 英文 + 符合 "calm, minimal" 产品哲学 |
| **离线模式** | A | 禁用 AI 评分按钮 + 温和提示 |
| **实施方式** | A | 完整审核后执行（本文档） |

---

## 🎯 错误提示语设计（符合产品哲学）

### 设计原则
- ✅ **Calm, not alarming**: 用 "That's all for today" 而非 "Error: Quota exceeded"
- ✅ **Natural, not technical**: 像朋友对话，不像系统报错
- ✅ **Breathing room**: 简短、留白、不急迫
- ✅ **No guilt**: 不让用户感到自己做错了什么

### 具体错误提示

```swift
enum BackendError: LocalizedError {
    case dailyLimitReached
    case networkError(Error)
    case invalidResponse
    case timeout
    case rateLimited
    case missingDeviceID

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached:
            return "That's all for today. Come back tomorrow to continue practicing."

        case .networkError:
            return "No connection. Check your network and try again."

        case .invalidResponse:
            return "Something went wrong. Please try again."

        case .timeout:
            return "This is taking longer than usual. Try again in a moment."

        case .rateLimited:
            return "Too many requests. Take a short break and try again."

        case .missingDeviceID:
            return "Device setup incomplete. Reinstalling the app may help."
        }
    }
}
```

---

## 📦 完整实施路线图（共 7 个 Phase，15-20 小时）

### Phase 0: Cloudflare Workers 账号设置（1-2 小时）
### Phase 1: 后端实现（4-6 小时）
### Phase 2: iOS Protocol 抽象层（2-3 小时）
### Phase 3: KeychainManager 扩展（1 小时）
### Phase 4: ViewModel 集成（2-3 小时）
### Phase 5: Settings UI 更新（1 小时）
### Phase 6: 测试与验证（3-4 小时）
### Phase 7: 部署与回滚计划（2-3 小时）

---

## 📦 Phase 0: Cloudflare Workers 账号设置（1-2 小时）

详细步骤见上方已生成内容...

## 📦 Phase 1: 后端实现（4-6 小时）

详细步骤见上方已生成内容...

## 📦 Phase 2: iOS Protocol 抽象层（2-3 小时）

### Step 2.1: 创建目录结构

```bash
cd /Users/charlie/Desktop/IELTSPart2Coach/IELTSPart2Coach
mkdir -p Protocols
```

### Step 2.2: 创建 AIBackendProtocol.swift

文件已在上方生成...

### Step 2.3: 创建 CloudflareBackend.swift（完整实现）

**文件路径**: `IELTSPart2Coach/Services/CloudflareBackend.swift`

**完整代码**（800+ 行）：

```swift
//
//  CloudflareBackend.swift
//  IELTSPart2Coach
//
//  Cloudflare Workers backend implementation
//  Phase 7-8: Unified backend architecture
//

import Foundation

@MainActor
class CloudflareBackend: AIBackendProtocol {
    static let shared = CloudflareBackend()

    // ⚠️ IMPORTANT: 替换为您的 Worker URL
    private let baseURL = "https://ielts-coach-api.YOUR-SUBDOMAIN.workers.dev"
    private let timeout: TimeInterval = 60.0  // 增加到 60s（后端代理增加延迟）

    private init() {}

    // MARK: - Device ID Management

    /// 获取或创建设备 ID
    private func getDeviceID() throws -> String {
        do {
            return try KeychainManager.shared.getDeviceID()
        } catch KeychainError.keyNotFound {
            // 首次启动：生成新 UUID
            let newID = UUID().uuidString
            try KeychainManager.shared.saveDeviceID(newID)

            #if DEBUG
            print("✅ Generated new device ID: \(newID.prefix(8))...")
            #endif

            return newID
        }
    }

    // MARK: - AIBackendProtocol Implementation

    /// 生成个性化 IELTS Part 2 题目
    func generatePersonalizedTopic(
        userProgress: UserProgress?,
        excludeRecent: [String] = []
    ) async throws -> Topic {
        let deviceID = try getDeviceID()
        let url = URL(string: "\(baseURL)/api/generate-topic")!

        // 构建请求体
        var requestBody: [String: Any] = [
            "excludeRecent": excludeRecent
        ]

        // 添加 userProgress（如果存在）
        if let progress = userProgress {
            requestBody["userProgress"] = [
                "totalSessions": progress.totalSessions,
                "averageFluency": progress.averageFluency,
                "averageLexical": progress.averageLexical,
                "averageGrammar": progress.averageGrammar,
                "averagePronunciation": progress.averagePronunciation
            ]
        }

        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.allHTTPHeaderFields = makeHeaders(deviceID: deviceID)
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // 发送请求（ephemeral session，不缓存）
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(for: request)

            // 检查 HTTP 状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                // 成功：解析 Topic
                return try parseTopicResponse(data: data)

            case 429:
                // 检查是每日限流还是 OpenRouter 限流
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String,
                   error == "dailyLimitReached" {
                    throw BackendError.dailyLimitReached
                }
                throw BackendError.rateLimited

            case 400...499, 500...599:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                #if DEBUG
                print("⚠️ Backend Error [\(httpResponse.statusCode)]: \(message)")
                #endif
                throw BackendError.apiError(statusCode: httpResponse.statusCode, message: message)

            default:
                throw BackendError.invalidResponse
            }

        } catch let error as BackendError {
            throw error
        } catch {
            // 网络错误或超时
            if (error as NSError).code == NSURLErrorTimedOut {
                throw BackendError.timeout
            }
            throw BackendError.networkError(error)
        }
    }

    /// 分析语音录音并返回反馈
    func analyzeSpeech(
        audioURL: URL,
        duration: TimeInterval
    ) async throws -> FeedbackResult {
        let deviceID = try getDeviceID()
        let url = URL(string: "\(baseURL)/api/analyze-speech")!

        // Base64 编码音频（异步，后台线程）
        let base64Audio = try await Task.detached(priority: .userInitiated) {
            let audioData = try Data(contentsOf: audioURL)
            let sizeKB = audioData.count / 1024

            #if DEBUG
            print("📦 Audio size: \(sizeKB)KB (encoding on background thread)")
            #endif

            // 验证文件大小（Cloudflare Workers 限制 100MB，保守限制 10MB）
            guard audioData.count < 10_000_000 else {
                throw BackendError.audioTooLarge
            }

            return audioData.base64EncodedString()
        }.value

        // 构建请求体
        let requestBody: [String: Any] = [
            "audioBase64": base64Audio,
            "audioFormat": "wav",
            "duration": duration
        ]

        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.allHTTPHeaderFields = makeHeaders(deviceID: deviceID)
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // 发送请求（ephemeral session，不缓存音频）
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(for: request)

            // 检查 HTTP 状态码
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                // 成功：解析 FeedbackResult
                return try parseFeedbackResponse(data: data, duration: duration)

            case 429:
                // 检查是每日限流还是 OpenRouter 限流
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String,
                   error == "dailyLimitReached" {
                    throw BackendError.dailyLimitReached
                }
                throw BackendError.rateLimited

            case 400...499, 500...599:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                #if DEBUG
                print("⚠️ Backend Error [\(httpResponse.statusCode)]: \(message)")
                #endif
                throw BackendError.apiError(statusCode: httpResponse.statusCode, message: message)

            default:
                throw BackendError.invalidResponse
            }

        } catch let error as BackendError {
            throw error
        } catch {
            // 网络错误或超时
            if (error as NSError).code == NSURLErrorTimedOut {
                throw BackendError.timeout
            }
            throw BackendError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    /// 构建请求 headers
    private func makeHeaders(deviceID: String) -> [String: String] {
        return [
            "X-Device-ID": deviceID,
            "Content-Type": "application/json",
            "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "X-Platform": "iOS"
        ]
    }

    /// 解析题目生成响应
    private func parseTopicResponse(data: Data) throws -> Topic {
        do {
            // 后端直接返回 {title, prompts} 格式（不是 OpenRouter 包装）
            let topicData = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let title = topicData?["title"] as? String,
                  !title.isEmpty else {
                #if DEBUG
                print("❌ Invalid topic response: missing or empty title")
                logRawResponse(data)
                #endif
                throw BackendError.invalidResponse
            }

            let prompts = topicData?["prompts"] as? [String]

            // 创建 Topic 对象
            let topic = Topic(id: UUID(), title: title, prompts: prompts)

            #if DEBUG
            print("✨ AI Topic Generated: \(title)")
            #endif

            return topic

        } catch {
            #if DEBUG
            print("❌ Topic parsing error: \(error)")
            logRawResponse(data)
            #endif
            throw BackendError.invalidResponse
        }
    }

    /// 解析反馈响应
    private func parseFeedbackResponse(data: Data, duration: TimeInterval) throws -> FeedbackResult {
        do {
            // 后端返回的是直接的 FeedbackResult JSON（不是 OpenRouter 包装）
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase  // action_tip → actionTip

            var result = try decoder.decode(FeedbackResult.self, from: data)

            // 验证分数范围
            let allScores = [
                result.bands.fluency.score,
                result.bands.lexical.score,
                result.bands.grammar.score,
                result.bands.pronunciation.score
            ]

            guard allScores.allSatisfy({ $0 >= 0.0 && $0 <= 9.0 }) else {
                #if DEBUG
                print("⚠️ Invalid score range detected")
                #endif
                throw BackendError.invalidResponse
            }

            // 清理 quote（应用本地规则）
            result = FeedbackResult(
                summary: result.summary,
                actionTip: result.actionTip,
                bands: result.bands,
                quote: sanitizeQuote(result.quote, duration: duration)
            )

            return result

        } catch let decodingError as DecodingError {
            #if DEBUG
            print("❌ Decoding error: \(decodingError)")
            logRawResponse(data)
            #endif
            throw BackendError.invalidResponse
        } catch {
            throw error
        }
    }

    /// 清理 quote（与 GeminiService 相同逻辑）
    private func sanitizeQuote(_ quote: String, duration: TimeInterval) -> String {
        // 短录音禁止 quote
        guard duration >= 12.0 else {
            return ""
        }

        // 只保留英文字符
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ,.'?!-")
        let filtered = quote.unicodeScalars.filter { allowedCharacterSet.contains($0) }
        let cleaned = String(String.UnicodeScalarView(filtered))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证长度
        guard cleaned.count >= 5, cleaned.count <= 80 else {
            return ""
        }

        // 过滤模板语言
        let forbiddenTemplates = [
            "I would like to describe",
            "Today I'm going to talk about",
            "There was a time when",
            "Let me tell you",
            "The thing I want to describe",
            "I want to talk about",
            "Let me describe",
            "I'm going to tell you about",
            "One thing I'd like to talk about",
            "I'm going to describe",
            "I want to share"
        ]

        let lowercased = cleaned.lowercased()
        for template in forbiddenTemplates {
            if lowercased.hasPrefix(template.lowercased()) {
                return ""
            }
        }

        return cleaned
    }

    /// 打印原始响应（调试用）
    private func logRawResponse(_ data: Data) {
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            let preview = jsonString.prefix(500)
            print("🔍 Raw response preview: \(preview)")
        }
        #endif
    }
}

// MARK: - Error Types

enum BackendError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case timeout
    case rateLimited
    case dailyLimitReached
    case apiError(statusCode: Int, message: String)
    case missingDeviceID
    case audioTooLarge

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached:
            return "That's all for today. Come back tomorrow to continue practicing."

        case .networkError:
            return "No connection. Check your network and try again."

        case .invalidResponse:
            return "Something went wrong. Please try again."

        case .timeout:
            return "This is taking longer than usual. Try again in a moment."

        case .rateLimited:
            return "Too many requests. Take a short break and try again."

        case .missingDeviceID:
            return "Device setup incomplete. Reinstalling the app may help."

        case .audioTooLarge:
            return "Recording too long. Keep it under 2 minutes."

        case .apiError(let statusCode, _):
            return "Analysis failed (code: \(statusCode)). Please try again."
        }
    }
}
```

**⚠️ 重要**: 记得替换 `baseURL` 为您的实际 Worker URL！

---

## 📦 Phase 3: KeychainManager 扩展（1 小时）

### Step 3.1: 修改 KeychainManager.swift

打开文件：`IELTSPart2Coach/Utilities/KeychainManager.swift`

**在文件末尾添加以下代码**（保持原有 API key 方法不动）：

```swift
// MARK: - Device ID Management (Phase 7-8: Backend Migration)

extension KeychainManager {
    private static let deviceIDKey = "device_id"

    /// 保存设备 ID 到 Keychain
    func saveDeviceID(_ id: String) throws {
        guard !id.isEmpty else {
            throw KeychainError.emptyKey
        }

        let keyData = id.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.deviceIDKey,
            kSecValueData as String: keyData
        ]

        // 删除旧值（如果存在）
        SecItemDelete(query as CFDictionary)

        // 添加新值
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            #if DEBUG
            print("❌ Failed to save device ID: \(status)")
            #endif
            throw KeychainError.saveFailed(status: status)
        }

        #if DEBUG
        print("✅ Device ID saved to Keychain: \(id.prefix(8))...")
        #endif
    }

    /// 从 Keychain 获取设备 ID
    func getDeviceID() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.deviceIDKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let keyData = result as? Data,
              let deviceID = String(data: keyData, encoding: .utf8) else {
            throw KeychainError.keyNotFound
        }

        return deviceID
    }

    /// 删除设备 ID
    func deleteDeviceID() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.deviceIDKey
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }

        #if DEBUG
        print("✅ Device ID deleted from Keychain")
        #endif
    }

    /// 检查是否已存储设备 ID
    func hasDeviceID() -> Bool {
        do {
            _ = try getDeviceID()
            return true
        } catch {
            return false
        }
    }
}
```

---

## 📦 Phase 4: ViewModel 集成（2-3 小时）

### Step 4.1: 修改 RecordingViewModel.swift

打开文件：`IELTSPart2Coach/ViewModels/RecordingViewModel.swift`

**修改 1**: 替换 GeminiService 依赖

找到：
```swift
private let geminiService = GeminiService.shared
```

替换为：
```swift
private let backend: AIBackendProtocol = CloudflareBackend.shared
```

---

**修改 2**: 更新 `loadRandomTopic()` 方法（第 410 行）

找到：
```swift
let topic = try await GeminiService.shared.generatePersonalizedTopic(
    userProgress: userProgress,
    excludeRecent: recentTopicTitles
)
```

替换为：
```swift
let topic = try await backend.generatePersonalizedTopic(
    userProgress: userProgress,
    excludeRecent: recentTopicTitles
)
```

---

**修改 3**: 更新 `loadNewTopic()` 方法（第 503 行）

找到：
```swift
let topic = try await GeminiService.shared.generatePersonalizedTopic(
    userProgress: userProgress,
    excludeRecent: recentTopicTitles
)
```

替换为：
```swift
let topic = try await backend.generatePersonalizedTopic(
    userProgress: userProgress,
    excludeRecent: recentTopicTitles
)
```

---

**修改 4**: 更新 `analyzeRecording()` 方法（第 881 行）

找到：
```swift
let result = try await GeminiService.shared.analyzeSpeech(
    audioURL: audioURL,
    duration: elapsedTime
)
```

替换为：
```swift
let result = try await backend.analyzeSpeech(
    audioURL: audioURL,
    duration: elapsedTime
)
```

---

**修改 5**: 添加每日限流错误处理

在 `analyzeRecording()` 方法的 `catch` 块中添加新 case：

找到：
```swift
} catch {
    Task { @MainActor in
        self.analysisError = error
        self.state = .finished

        #if DEBUG
        print("❌ Analysis failed: \(error.localizedDescription)")
        #endif
    }
}
```

替换为：
```swift
} catch let error as BackendError {
    Task { @MainActor in
        self.analysisError = error

        // 特殊处理每日限流错误
        if case .dailyLimitReached = error {
            self.showDailyLimitAlert = true
        }

        self.state = .finished

        #if DEBUG
        print("❌ Analysis failed: \(error.localizedDescription)")
        #endif
    }
} catch {
    Task { @MainActor in
        self.analysisError = error
        self.state = .finished

        #if DEBUG
        print("❌ Analysis failed: \(error.localizedDescription)")
        #endif
    }
}
```

---

**修改 6**: 添加 `showDailyLimitAlert` 状态变量

在 `RecordingViewModel` 类中添加（第 50 行附近，其他状态变量旁边）：

```swift
@Published var showDailyLimitAlert = false
```

---

### Step 4.2: 修改 QuestionCardView.swift

打开文件：`IELTSPart2Coach/Views/QuestionCardView.swift`

**添加每日限流 Alert**（在文件末尾 `.task` 后面添加）：

```swift
.alert("Daily Limit Reached", isPresented: $viewModel.showDailyLimitAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text("That's all for today. Come back tomorrow to continue practicing.")
        .font(.system(size: 15, weight: .regular, design: .rounded))
}
```

---

## 📦 Phase 5: Settings UI 更新（1 小时）

### Step 5.1: 修改 SettingsView.swift

打开文件：`IELTSPart2Coach/Views/SettingsView.swift`

**删除整个 API Key Section**（第 108-150 行）

找到并**完全删除**：
```swift
// MARK: - API Key Section (Phase 5)

private var apiKeySection: some View {
    Section {
        VStack(alignment: .leading, spacing: 12) {
            // ... 整个 section
        }
    } header: {
        Text("AI Service")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
    .sheet(isPresented: $viewModel.showAPIKeySheet) {
        APIKeySheetView()
    }
}
```

**同时删除 Form 中的引用**（第 28 行）：
```swift
// 删除这一行
apiKeySection
```

---

**添加设备信息 Section**（在 `transcriptSection` 后面添加）：

```swift
// MARK: - Device Information Section (Phase 7-8)

private var deviceInfoSection: some View {
    Section {
        VStack(alignment: .leading, spacing: 12) {
            // 设备 ID 显示
            HStack {
                Text("Device ID")
                    .font(.system(size: 16, weight: .regular, design: .rounded))

                Spacer()

                if let deviceID = try? KeychainManager.shared.getDeviceID() {
                    Text(deviceID.prefix(8) + "...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)  // 允许复制
                } else {
                    Text("Not set")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                }
            }

            // 说明文字
            Text("This anonymous ID is used to track your daily usage. No personal information is collected.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    } header: {
        Text("Device")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
```

**在 Form 中添加引用**（替换原来的 `apiKeySection`）：
```swift
Form {
    // Notifications Section (Phase 7.4 placeholder)
    notificationsSection

    // Device Information (Phase 7-8: Backend migration)
    deviceInfoSection  // ← 新增

    // Transcript Section (Phase 8.1)
    transcriptSection

    // ... 其他 sections
}
```

---

**删除 APIKeySheetView.swift 文件**：
```bash
rm /Users/charlie/Desktop/IELTSPart2Coach/IELTSPart2Coach/Views/Components/APIKeySheetView.swift
```

---

## 📦 Phase 6: 测试与验证（3-4 小时）

### Step 6.1: 单元测试（创建测试文件）

创建文件：`IELTSPart2CoachTests/CloudflareBackendTests.swift`

```swift
//
//  CloudflareBackendTests.swift
//  IELTSPart2CoachTests
//
//  Unit tests for Cloudflare backend integration
//

import XCTest
@testable import IELTSPart2Coach

@MainActor
final class CloudflareBackendTests: XCTestCase {

    var backend: CloudflareBackend!

    override func setUpWithError() throws {
        backend = CloudflareBackend.shared
    }

    // MARK: - Device ID Tests

    func testDeviceIDGeneration() throws {
        // 确保设备 ID 可以生成和获取
        let keychainManager = KeychainManager.shared

        // 清理旧数据
        try? keychainManager.deleteDeviceID()

        // 验证首次获取会生成新 ID
        XCTAssertFalse(keychainManager.hasDeviceID())

        // 首次调用后端（会触发 Device ID 生成）
        // 注意：这需要真实网络连接
        // 如果想测试离线场景，需要 mock
    }

    // MARK: - Topic Generation Tests

    func testGenerateTopicSuccess() async throws {
        // ⚠️ 需要真实网络连接
        let topic = try await backend.generatePersonalizedTopic(
            userProgress: nil,
            excludeRecent: []
        )

        XCTAssertFalse(topic.title.isEmpty, "Topic title should not be empty")
        XCTAssertNotNil(topic.prompts, "Topic prompts should exist")
    }

    func testGenerateTopicWithExclusions() async throws {
        // ⚠️ 需要真实网络连接
        let excludedTopics = [
            "Describe a memorable childhood experience",
            "Describe a place you like to visit"
        ]

        let topic = try await backend.generatePersonalizedTopic(
            userProgress: nil,
            excludeRecent: excludedTopics
        )

        // 验证生成的题目不在排除列表中
        XCTAssertFalse(excludedTopics.contains(topic.title), "Generated topic should not be in exclusion list")
    }

    // MARK: - Speech Analysis Tests

    func testAnalyzeSpeechWithValidAudio() async throws {
        // ⚠️ 需要真实音频文件 + 网络连接
        // 创建测试音频文件
        let testAudioURL = Bundle(for: type(of: self)).url(forResource: "test_recording", withExtension: "wav")

        guard let audioURL = testAudioURL else {
            XCTFail("Test audio file not found")
            return
        }

        let result = try await backend.analyzeSpeech(
            audioURL: audioURL,
            duration: 30.0
        )

        XCTAssertFalse(result.summary.isEmpty, "Summary should not be empty")
        XCTAssertFalse(result.actionTip.isEmpty, "Action tip should not be empty")

        // 验证分数范围
        XCTAssertTrue(result.bands.fluency.score >= 0.0 && result.bands.fluency.score <= 9.0)
        XCTAssertTrue(result.bands.lexical.score >= 0.0 && result.bands.lexical.score <= 9.0)
        XCTAssertTrue(result.bands.grammar.score >= 0.0 && result.bands.grammar.score <= 9.0)
        XCTAssertTrue(result.bands.pronunciation.score >= 0.0 && result.bands.pronunciation.score <= 9.0)
    }

    // MARK: - Error Handling Tests

    func testDailyLimitEnforcement() async {
        // ⚠️ 这个测试需要多次调用 backend（11 次）
        // 建议手动测试，或使用 mock

        // 模拟连续 11 次请求
        for i in 1...11 {
            do {
                let _ = try await backend.generatePersonalizedTopic(
                    userProgress: nil,
                    excludeRecent: []
                )

                if i <= 10 {
                    print("✅ Request \(i) succeeded (expected)")
                } else {
                    XCTFail("Request 11 should have failed with daily limit error")
                }

            } catch BackendError.dailyLimitReached {
                if i == 11 {
                    print("✅ Request 11 failed with daily limit (expected)")
                } else {
                    XCTFail("Unexpected daily limit error on request \(i)")
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testNetworkErrorHandling() async {
        // ⚠️ 需要模拟离线状态
        // 可以在飞行模式下运行此测试

        do {
            let _ = try await backend.generatePersonalizedTopic(
                userProgress: nil,
                excludeRecent: []
            )
            XCTFail("Should have thrown network error in offline mode")
        } catch BackendError.networkError {
            print("✅ Network error handled correctly")
        } catch {
            XCTFail("Expected networkError, got: \(error)")
        }
    }
}
```

**运行测试**：
```bash
# 在 Xcode 中
Cmd + U

# 或命令行
xcodebuild test -scheme IELTSPart2Coach -destination 'platform=iOS Simulator,name=iPhone 17'
```

---

### Step 6.2: 手动测试清单

#### 测试环境准备
- [ ] Cloudflare Worker 已部署并可访问
- [ ] iPhone 真机或模拟器（iOS 26.1+）
- [ ] 已更新 `CloudflareBackend.swift` 的 `baseURL`

#### 功能测试

**1. 首次启动（设备 ID 生成）**
- [ ] 删除 app 重新安装
- [ ] 打开 app，进入 Settings
- [ ] 验证 "Device ID" 显示 8 位字符串（如 `A1B2C3D4...`）
- [ ] 重启 app，验证 Device ID 保持不变

**2. 题目生成（网络连接）**
- [ ] 打开 app，点击 "New Topic"
- [ ] 验证生成新题目（加载时间 <10 秒）
- [ ] 再次点击 "New Topic"，验证题目不同
- [ ] 连续生成 5 个题目，验证都不重复

**3. 语音分析（网络连接）**
- [ ] 点击 "Start" 开始录音
- [ ] 说话 30-60 秒
- [ ] 点击 "Get AI feedback"
- [ ] 验证分析完成（<15 秒）
- [ ] 检查 FeedbackView 显示正常：
  - [ ] Summary 显示
  - [ ] Action tip 显示
  - [ ] Band scores 显示（4 个分数）
  - [ ] Quote 显示（可能为空）

**4. 每日限流测试**
- [ ] 连续分析 10 次语音（可以用相同录音）
- [ ] 第 10 次成功
- [ ] 第 11 次点击 "Get AI feedback"
- [ ] 验证 Alert 显示：
  ```
  Daily Limit Reached
  That's all for today. Come back tomorrow to continue practicing.
  ```
- [ ] 点击 "OK" 关闭 Alert
- [ ] 验证仍可录音和播放（只是无法分析）

**5. 离线模式测试**
- [ ] 开启飞行模式
- [ ] 点击 "New Topic"
- [ ] 验证显示错误提示（温和语气）
- [ ] 点击 "Get AI feedback"
- [ ] 验证显示 "No connection" 错误
- [ ] 关闭飞行模式
- [ ] 验证功能恢复正常

**6. Settings 界面验证**
- [ ] 进入 Settings
- [ ] 验证 **没有** "API Key" section（已删除）
- [ ] 验证显示 "Device" section
- [ ] 验证可以复制 Device ID（长按选择）

---

### Step 6.3: 性能测试

**测试指标**：

| 指标 | 目标值 | 实际值 |
|------|--------|--------|
| 题目生成延迟 | <10s | _______ |
| 语音分析延迟（60s 录音） | <15s | _______ |
| 应用启动时间 | <2s | _______ |
| 录音启动延迟 | <200ms | _______ |
| 内存占用（录音中） | <80MB | _______ |

**测试方法**：
1. 使用 Xcode Instruments → Time Profiler 测试
2. 检查主线程是否阻塞
3. 验证网络请求未阻塞 UI

---

## 📦 Phase 7: 部署与回滚计划（2-3 小时）

### Step 7.1: Git 版本管理

```bash
cd /Users/charlie/Desktop/IELTSPart2Coach

# 创建功能分支
git checkout -b feature/cloudflare-backend-migration

# 提交所有改动
git add .
git commit -m "feat(backend): Migrate to Cloudflare Workers unified backend

- Remove BYOK model and API key UI
- Add Protocol-based backend abstraction (AIBackendProtocol)
- Implement CloudflareBackend with device ID management
- Add daily limit enforcement (10 requests/day)
- Update error messages to match product philosophy
- Extend KeychainManager for device ID storage
- Remove APIKeySheetView (no longer needed)
- Add device info section in Settings

Breaking changes:
- Existing users will lose configured API keys (auto-migration)
- All users now use unified backend (no BYOK option)

Phase: 7-8 Backend Migration
Estimated time: 15-20 hours
Status: Ready for testing"

# 推送到 GitHub
git push origin feature/cloudflare-backend-migration
```

---

### Step 7.2: 创建 Pull Request（审核点）

1. 访问 GitHub 仓库
2. 创建 Pull Request: `feature/cloudflare-backend-migration` → `main`
3. PR 描述模板：

```markdown
## 🚀 Backend Migration: BYOK → Cloudflare Workers

### Summary
Migrates from BYOK (Bring Your Own Key) model to unified Cloudflare Workers backend architecture.

### Changes
- ✅ Protocol-based abstraction (`AIBackendProtocol`)
- ✅ Cloudflare Workers proxy for OpenRouter API
- ✅ Device ID management (UUID + Keychain)
- ✅ Daily limit enforcement (10 requests/day via KV store)
- ✅ Calm error messages ("That's all for today...")
- ❌ Removed API key configuration UI
- ❌ Deleted `APIKeySheetView.swift`

### Breaking Changes
- Existing users' API keys will be discarded
- No backward compatibility with BYOK mode

### Testing
- [x] Unit tests pass
- [x] Manual testing on iPhone 16
- [x] Daily limit enforcement verified
- [x] Offline mode tested
- [x] Settings UI updated

### Deployment
- Backend: `https://ielts-coach-api.YOUR-SUBDOMAIN.workers.dev`
- KV Namespace: `USAGE_TRACKER`
- Environment: OpenRouter API key configured

### Rollback Plan
See `BACKEND_IMPLEMENTATION_PLAN.md` Section 7.4
```

---

### Step 7.3: TestFlight 部署

#### 准备 Archive

```bash
# 在 Xcode 中
# 1. 选择 "Any iOS Device (arm64)" 作为目标
# 2. Product → Archive
# 3. 等待构建完成（3-5 分钟）
```

#### 上传到 App Store Connect

1. Archive 完成后，Organizer 窗口会打开
2. 选择最新的 Archive
3. 点击 **"Distribute App"**
4. 选择 **"App Store Connect"**
5. 选择 **"Upload"**
6. 验证设置：
   - Include bitcode: **OFF**（iOS 不再需要）
   - Upload symbols: **ON**（崩溃报告）
7. 点击 **"Upload"**
8. 等待处理（10-30 分钟）

#### 创建 TestFlight Beta

1. 登录 App Store Connect
2. 进入 "TestFlight" 标签
3. 选择刚上传的构建版本
4. 添加 **"What to Test"** 说明：

```
Backend Migration: Unified Cloudflare Workers

🔧 Major Changes:
- All users now use unified backend (no API key needed)
- Daily limit: 10 AI analyses per day
- New error messages with calm, minimal tone

🧪 Please Test:
1. Generate 5+ topics (verify variety)
2. Analyze 2-3 recordings (check feedback quality)
3. Try to analyze 11th time (should show daily limit alert)
4. Test offline mode (airplane mode → error handling)
5. Check Settings → Device section (Device ID display)

⚠️ Known Issues:
- Latency may be 1-2s slower than direct API (backend proxy)
- Daily limit resets at UTC midnight (not local time)

📧 Feedback: charliewang0322@gmail.com
```

5. 添加测试用户（Email）
6. 点击 **"Submit for Review"**（内部测试）

---

### Step 7.4: 回滚计划（如果出现严重问题）

#### 场景 1：Cloudflare Worker 宕机

**症状**：所有用户无法生成题目或分析语音

**立即行动**：
1. 检查 Worker 状态：
   ```bash
   curl https://ielts-coach-api.YOUR-SUBDOMAIN.workers.dev/health
   ```
2. 如果返回错误，重新部署 Worker：
   ```bash
   cd ielts-coach-backend
   wrangler deploy --force
   ```

**紧急回滚**（如果 Worker 无法修复）：
1. 创建 Git 回滚分支：
   ```bash
   git checkout main
   git checkout -b hotfix/revert-backend-migration
   git revert <commit-hash>  # 回退到 BYOK 版本
   ```
2. 重新构建 App
3. 上传新 TestFlight 版本
4. 通知测试用户切换回老版本

**预计恢复时间**: 1-2 小时

---

#### 场景 2：每日限流过于严格（用户反馈）

**症状**：大量用户抱怨 10 次/天不够用

**解决方案**（无需重新发版）：
1. 修改 Cloudflare Worker 环境变量：
   ```
   Workers & Pages → ielts-coach-api → Settings → Variables
   ```
2. 将 `DAILY_LIMIT` 从 `10` 改为 `20`
3. 点击 **"Save and Deploy"**
4. 立即生效（无需重启 Worker）

**无需回滚 iOS 代码**

---

#### 场景 3：Device ID 冲突（极低概率）

**症状**：两个用户共享同一个每日限额

**根因**：UUID 碰撞（概率 ~10⁻³⁶）

**解决方案**：
1. 添加后端校验逻辑（Worker 侧）：
   ```javascript
   // 检测异常高频请求
   if (requestsPerHour > 100) {
     // 可能是碰撞或滥用
     await logSuspiciousActivity(deviceID);
   }
   ```
2. 引导用户重置 Device ID：
   - Settings → 添加 "Reset Device ID" 按钮
   - 删除旧 ID，重新生成新 ID

**无需回滚**，修复后推送新版本

---

#### 场景 4：OpenRouter API 成本暴涨

**症状**：月账单超出预算（>$1000）

**立即行动**：
1. 检查 Cloudflare KV 使用数据：
   ```bash
   wrangler kv:key list --binding=USAGE_KV
   ```
2. 分析异常设备 ID（超高频请求）
3. 临时降低每日限额到 5 次/天
4. 添加 IP 级别限流（Worker 侧）

**长期方案**：
- 实施付费订阅（Phase 9）
- 添加设备黑名单机制
- 监控每日成本并设置预警

---

### Step 7.5: 监控与警报

#### Cloudflare Analytics

访问：`https://dash.cloudflare.com/ → Analytics & Logs → Workers`

**关键指标**：
- Requests per day
- Error rate (4xx/5xx)
- P50/P95/P99 latency
- CPU time usage

**设置警报**：
1. 进入 `Notifications`
2. 创建新通知：
   - **Error rate > 5%**: Email alert
   - **Requests > 100k/day**: Cost warning
   - **Worker execution errors**: Immediate notification

#### OpenRouter Usage Monitoring

1. 登录 OpenRouter Dashboard
2. 查看 **"Usage"** 标签
3. 监控：
   - Requests per day
   - Cost per day
   - Token usage

**预算警报**：
- 设置月预算：$200
- 达到 80% 时发送警报邮件

---

## 📚 附录

### A. 完整文件清单

#### 后端文件（Cloudflare Workers）
```
ielts-coach-backend/
├── wrangler.toml                    # Cloudflare 配置
├── src/
│   ├── index.js                     # 主入口（路由）
│   ├── handlers/
│   │   ├── generateTopic.js         # 题目生成 handler
│   │   └── analyzeSpeech.js         # 语音分析 handler
│   └── utils/
│       ├── rateLimiter.js           # 每日限流
│       └── openrouterClient.js      # OpenRouter 客户端
└── package.json
```

#### iOS 新增文件
```
IELTSPart2Coach/
├── Protocols/
│   └── AIBackendProtocol.swift      # 后端抽象协议（新增）
└── Services/
    └── CloudflareBackend.swift      # Cloudflare 实现（新增）
```

#### iOS 修改文件
```
IELTSPart2Coach/
├── Utilities/
│   └── KeychainManager.swift        # 扩展 Device ID 方法
├── ViewModels/
│   └── RecordingViewModel.swift     # 替换 backend 依赖
├── Views/
│   ├── QuestionCardView.swift       # 添加每日限流 alert
│   └── SettingsView.swift           # 删除 API key section，添加 device info
└── Models/
    └── FeedbackResult.swift         # （无改动）
```

#### iOS 删除文件
```
IELTSPart2Coach/Views/Components/
└── APIKeySheetView.swift            # 删除（不再需要）
```

---

### B. 环境变量配置

#### Cloudflare Worker 环境变量

| 变量名 | 类型 | 值 | 说明 |
|--------|------|----|----|
| `OPENROUTER_API_KEY` | Secret | `sk-or-v1-...` | OpenRouter API key（加密存储）|
| `DAILY_LIMIT` | Text | `10` | 每日请求限制 |
| `USAGE_KV` | KV Binding | (自动绑定) | KV Namespace 用于存储使用数据 |

#### iOS 环境变量（开发用）

| 变量名 | 值 | 说明 |
|--------|----|----|
| `BACKEND_BASE_URL` | `https://ielts-coach-api...workers.dev` | Worker URL（硬编码在代码中）|

---

### C. 成本估算

#### Cloudflare Costs（免费套餐足够）

| 项目 | 免费额度 | 预计使用 | 超出成本 |
|------|---------|---------|---------|
| Worker 请求 | 100k 请求/天 | ~1k-5k/天 | $0 |
| KV 读取 | 100k 次/天 | ~2k-10k/天 | $0 |
| KV 写入 | 1k 次/天 | ~1k-5k/天 | 可能超出 |
| KV 存储 | 1GB | <10MB | $0 |

**总计**: **$0-5/月**（KV 写入可能超限）

#### OpenRouter Costs

| 场景 | 请求量 | 单价 | 月成本 |
|------|--------|------|--------|
| 100 活跃用户 | 100 × 10/天 × 30天 = 30k 请求 | $0.02/次 | $600 |
| 实际使用率 30% | 9k 请求 | $0.02/次 | **$180** |
| 1000 活跃用户 | 9k × 10 = 90k 请求 | $0.02/次 | **$1,800** |

**预计月成本**: $200-500（取决于用户量）

---

### D. 常见问题（FAQ）

**Q1: 为什么不用 Firebase 或 AWS？**
A: Cloudflare Workers 的优势：
- ✅ 全球边缘节点（延迟更低）
- ✅ 免费套餐慷慨（100k 请求/天）
- ✅ 部署简单（`wrangler deploy`）
- ✅ 无需管理服务器

**Q2: Device ID 会不会泄露用户隐私？**
A: 不会：
- Device ID 是随机 UUID（无法反推用户信息）
- 不关联 Apple ID 或 IDFA
- 重装 app 会重置 ID

**Q3: 每日限流能否动态调整？**
A: 可以：
- 修改 Cloudflare 环境变量 `DAILY_LIMIT`
- 无需重新发版 iOS app
- 立即生效

**Q4: 如果 Cloudflare Worker 挂了怎么办？**
A: 多层保护：
- Worker 自动故障转移（全球边缘节点）
- 99.9% SLA 保障
- 降级方案：iOS app 可回退到本地题目库

**Q5: 未来能否支持 BYOK 模式（高级用户）？**
A: 可以（通过 Protocol 抽象）：
- 保留 `GeminiService.swift`（改名为 `BYOKBackend.swift`）
- Settings 添加 "Developer Mode" 开关
- 两种模式并存

---

## ✅ 实施清单总结

在开始执行前，请确认：

### 前置条件
- [ ] 已注册 Cloudflare 账号
- [ ] 已创建 Worker 项目和 KV Namespace
- [ ] 已配置 OpenRouter API key
- [ ] 已安装 Node.js 和 Wrangler CLI
- [ ] 已获取 Worker URL（`https://ielts-coach-api...workers.dev`）

### Phase 0-1（后端）
- [ ] Cloudflare Worker 代码已部署
- [ ] 本地测试通过（`wrangler dev`）
- [ ] 生产环境测试通过（`curl` 验证）
- [ ] KV store 正常工作（限流测试）

### Phase 2-5（iOS）
- [ ] `AIBackendProtocol.swift` 已创建
- [ ] `CloudflareBackend.swift` 已创建（URL 已替换）
- [ ] `KeychainManager` 已扩展（Device ID 方法）
- [ ] `RecordingViewModel` 已更新（backend 依赖）
- [ ] `QuestionCardView` 已更新（Alert）
- [ ] `SettingsView` 已更新（删除 API key，添加 Device info）
- [ ] `APIKeySheetView.swift` 已删除
- [ ] Xcode 编译通过（0 errors）

### Phase 6-7（测试与部署）
- [ ] 单元测试已运行
- [ ] 真机手动测试完成（所有清单项）
- [ ] 每日限流验证通过（11 次请求测试）
- [ ] Git 分支已创建并推送
- [ ] Pull Request 已创建
- [ ] TestFlight 构建已上传
- [ ] Beta 测试说明已添加

### 文档与监控
- [ ] 回滚计划已准备
- [ ] Cloudflare Analytics 已设置警报
- [ ] OpenRouter 预算监控已配置
- [ ] 团队成员已知晓新架构

---

## 🎯 下一步行动

**立即执行**：
1. 审核本文档（15-20 分钟）
2. 确认所有决策无误
3. 回复 "可以执行" 开始实施

**执行顺序**：
- **Day 1-2**: Phase 0-1（后端部署）
- **Day 3-4**: Phase 2-5（iOS 代码改动）
- **Day 5**: Phase 6（测试）
- **Day 6**: Phase 7（部署 TestFlight）

**预计完成时间**: 6 天（每天 3-4 小时）

---

**文档版本**: 1.0
**作者**: Claude (Backend Architect)
**生成时间**: 2025-11-22
**状态**: ✅ Ready for Review and Execution

---

## 📮 联系方式

如有任何问题，请联系：
- **开发者**: charliewang0322@gmail.com
- **GitHub**: https://github.com/charliewang0322/IELTSPart2Coach
- **支持文档**: 本文件（`BACKEND_IMPLEMENTATION_PLAN.md`）

祝迁移顺利！🚀
