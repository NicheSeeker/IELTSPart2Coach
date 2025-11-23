# Backend Migration Testing Checklist

**Purpose**: Systematic verification guide for backend proxy migration before production deployment.

**Migration Date**: 2025-11-22
**Backend**: Cloudflare Workers
**Rate Limit**: 10 requests/device/day

---

## Pre-Deployment Testing (Local Environment)

### 1. Cloudflare Worker Local Testing

**Environment**: Wrangler Dev Server (`wrangler dev`)

#### 1.1 Worker Startup Verification
```bash
cd your-worker-project
wrangler dev
```

**Expected Output**:
```
⛅️ wrangler 3.x.x
------------------
⎔ Starting local server...
[wrangler:inf] Ready on http://localhost:8787
```

- [ ] Worker starts without errors
- [ ] Port 8787 is accessible
- [ ] No CORS or KV binding errors in console

---

#### 1.2 Generate Topic Endpoint Test

**cURL Command**:
```bash
curl -X POST http://localhost:8787/generate-topic \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: test-device-123" \
  -d '{
    "model": "google/gemini-2.5-flash",
    "messages": [
      {
        "role": "user",
        "content": "Generate an IELTS Speaking Part 2 topic about childhood memories"
      }
    ]
  }'
```

**Expected Response** (200 OK):
```json
{
  "id": "gen-...",
  "choices": [
    {
      "message": {
        "content": "Describe a memorable moment from your childhood..."
      }
    }
  ]
}
```

**Verification**:
- [ ] HTTP 200 status code
- [ ] Valid JSON response with `choices` array
- [ ] Topic content is coherent and IELTS-style
- [ ] Response time < 5 seconds

---

#### 1.3 Analyze Speech Endpoint Test

**Test Audio Preparation**:
1. Record 30-second IELTS practice audio in app (DEBUG build)
2. Locate audio file in app's temporary directory
3. Convert to base64:
   ```bash
   base64 -i recording.m4a -o audio.txt
   ```

**cURL Command**:
```bash
curl -X POST http://localhost:8787/analyze-speech \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: test-device-123" \
  -d @payload.json
```

**payload.json**:
```json
{
  "model": "google/gemini-2.5-flash",
  "response_format": {"type": "json_object"},
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "<Your IELTS examiner prompt>"
        },
        {
          "type": "input_audio",
          "input_audio": {
            "data": "<base64-encoded-m4a>",
            "format": "m4a"
          }
        }
      ]
    }
  ]
}
```

**Expected Response** (200 OK):
```json
{
  "summary": "Your story was engaging...",
  "action_tip": "Try varying your sentence rhythm...",
  "bands": {
    "fluency": {"score": 6.5, "comment": "Good pacing..."},
    "lexical_resource": {"score": 6.5, "comment": "Accurate word choice..."},
    "grammar": {"score": 6.0, "comment": "Generally correct..."},
    "pronunciation": {"score": 6.5, "comment": "Clear articulation..."}
  },
  "quote": "Actually I think it was when..."
}
```

**Verification**:
- [ ] HTTP 200 status code
- [ ] All required fields present (`summary`, `action_tip`, `bands`, `quote`)
- [ ] Band scores are 0.0-9.0 range
- [ ] Response time < 45 seconds
- [ ] No JSON parsing errors

---

#### 1.4 Rate Limiting Test (Local)

**Goal**: Verify daily limit enforcement (10 requests/device)

**Test Script**:
```bash
# Run 11 consecutive requests with same Device ID
for i in {1..11}; do
  echo "Request $i:"
  curl -X POST http://localhost:8787/generate-topic \
    -H "X-Device-ID: rate-limit-test-device" \
    -H "Content-Type: application/json" \
    -d '{"model":"google/gemini-2.5-flash","messages":[{"role":"user","content":"Test"}]}'
  echo -e "\n---"
done
```

**Expected Behavior**:
- [ ] Requests 1-10: HTTP 200 (successful)
- [ ] Request 11: HTTP 429 (rate limited)
- [ ] 429 response body: `{"error": "dailyLimitReached"}`

**KV Store Verification** (Optional):
```bash
# Check KV entry after test
wrangler kv:key get "usage:rate-limit-test-device" --binding USAGE
```

**Expected Output**:
```json
{
  "count": 10,
  "date": "2025-11-22"
}
```

---

### 2. iOS App Integration Testing (Simulator + DEBUG Build)

#### 2.1 Update iOS Code with Local Worker URL

**File**: `IELTSPart2Coach/Services/GeminiService.swift`

**Verify**:
```swift
#if DEBUG
private let baseURL = "http://localhost:8787"  // ✅ Correct for local testing
#else
private let baseURL = "https://ielts-api.YOUR-WORKER-NAME.workers.dev"
#endif
```

- [ ] DEBUG build points to `localhost:8787`
- [ ] Worker server is running (`wrangler dev`)

---

#### 2.2 Record & Analyze Flow Test

**Steps**:
1. Launch app in Simulator (iPhone 17, iOS 26.1)
2. Tap "Start" → Record 30s audio
3. Tap "Stop" → Tap "Get AI feedback"
4. Observe analyzing state (breathing animation)
5. Wait for feedback sheet presentation

**Expected Results**:
- [ ] Recording completes successfully
- [ ] "Listening to you..." animation displays
- [ ] No network timeout errors
- [ ] Feedback sheet presents with valid data:
  - [ ] Summary text (40-60 words)
  - [ ] Action tip (≤25 words)
  - [ ] Quote extracted from speech
  - [ ] All 4 band scores present
- [ ] iOS logs show Device ID in request headers

**Check Xcode Console for**:
```
🆔 Generated new device ID: <UUID>
✅ Analysis completed in X.X seconds
```

---

#### 2.3 Daily Limit Enforcement (iOS)

**Test Scenario**: Exhaust daily limit and verify user-facing error

**Steps**:
1. Complete 10 successful AI analysis requests
2. Attempt 11th request
3. Observe error alert

**Expected Results**:
- [ ] Request 11 fails with friendly error message:
   > "That's all for today. Come back tomorrow to continue practicing."
- [ ] No crash or unhandled exception
- [ ] User can dismiss alert and continue using app (recording still works)
- [ ] Same Device ID used across all 11 requests

**Verification in Xcode Console**:
```
⚠️ Daily limit reached for device: <UUID>
❌ Analysis failed: dailyLimitReached
```

---

#### 2.4 Network Failure Handling

**Test Scenarios**:

**A. Worker Offline**:
1. Stop `wrangler dev` server
2. Attempt AI analysis in app
3. Expected error: "Network connection failed. Please check your internet."

**B. Invalid Response**:
1. Modify Worker to return malformed JSON
2. Attempt AI analysis
3. Expected error: "Invalid response format."

**C. Timeout Simulation**:
1. Add artificial delay in Worker (>45s)
2. Attempt AI analysis
3. Expected error: "Analysis timed out. Please try again."

**Verification**:
- [ ] All errors display user-friendly alerts
- [ ] No app crashes
- [ ] User can retry after dismissing alert
- [ ] Recording is preserved (not deleted)

---

## Production Deployment Testing

### 3. Cloudflare Workers Deployment

#### 3.1 Deploy to Production

```bash
wrangler deploy
```

**Expected Output**:
```
 ⛅️ wrangler 3.x.x
------------------
Total Upload: X.XX KiB / gzip: X.XX KiB
Uploaded your-worker-name (X.XX sec)
Published your-worker-name (X.XX sec)
  https://ielts-api.your-worker-name.workers.dev
```

- [ ] Deployment succeeds without errors
- [ ] Worker URL is displayed
- [ ] Accessible via browser (CORS allowed for GET requests)

---

#### 3.2 Production Worker Health Check

**Browser Test**:
```
Open: https://ielts-api.YOUR-WORKER-NAME.workers.dev/
```

**Expected Response** (if root endpoint defined):
```json
{
  "status": "ok",
  "service": "IELTS Part 2 Coach Backend",
  "version": "1.0.0"
}
```

**OR**:
- [ ] 404 Not Found (acceptable if root route not defined)
- [ ] Worker logs show no startup errors in Cloudflare Dashboard

---

#### 3.3 Production cURL Testing

**Generate Topic Test**:
```bash
curl -X POST https://ielts-api.YOUR-WORKER-NAME.workers.dev/generate-topic \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: prod-test-device" \
  -d '{
    "model": "google/gemini-2.5-flash",
    "messages": [
      {
        "role": "user",
        "content": "Generate an IELTS topic about travel"
      }
    ]
  }'
```

**Expected**:
- [ ] HTTP 200 OK
- [ ] Valid topic generation response
- [ ] Response time < 5s (may vary by region)

**Analyze Speech Test**:
```bash
curl -X POST https://ielts-api.YOUR-WORKER-NAME.workers.dev/analyze-speech \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: prod-test-device" \
  -d @payload.json  # Same payload from Section 1.3
```

**Expected**:
- [ ] HTTP 200 OK
- [ ] Valid feedback JSON response
- [ ] Response time < 45s

---

#### 3.4 Production Rate Limiting Test

**Warning**: This will consume 11 requests from your OpenRouter API quota.

**Test Script**:
```bash
for i in {1..11}; do
  echo "Production Request $i:"
  curl -X POST https://ielts-api.YOUR-WORKER-NAME.workers.dev/generate-topic \
    -H "X-Device-ID: prod-rate-limit-test" \
    -H "Content-Type: application/json" \
    -d '{"model":"google/gemini-2.5-flash","messages":[{"role":"user","content":"Test"}]}'
  echo -e "\n---"
done
```

**Expected**:
- [ ] Requests 1-10: HTTP 200
- [ ] Request 11: HTTP 429 with `{"error": "dailyLimitReached"}`

**Cloudflare KV Verification**:
1. Go to Cloudflare Dashboard → Workers & Pages → KV
2. Select "USAGE" namespace
3. Find key: `usage:prod-rate-limit-test`
4. Verify value: `{"count": 10, "date": "2025-11-22"}`

---

### 4. iOS App Production Build Testing

#### 4.1 Update Production Worker URL

**File**: `IELTSPart2Coach/Services/GeminiService.swift`

**Change**:
```swift
#if DEBUG
private let baseURL = "http://localhost:8787"
#else
private let baseURL = "https://ielts-api.YOUR-WORKER-NAME.workers.dev"
                      // ⚠️ REPLACE 'YOUR-WORKER-NAME' with actual Worker subdomain
#endif
```

**Verification**:
- [ ] Worker URL matches deployment output
- [ ] No trailing slashes
- [ ] HTTPS protocol (not HTTP)

---

#### 4.2 Archive & Export Release Build

**Xcode Steps**:
1. Product → Scheme → Edit Scheme → Run → Build Configuration → Release
2. Product → Archive
3. Distribute App → Development (for testing)
4. Export .ipa file

**OR Use TestFlight**:
1. Distribute App → App Store Connect
2. Upload to TestFlight
3. Install on real device via TestFlight

**Verification**:
- [ ] Archive builds successfully
- [ ] No compiler warnings about deprecated code
- [ ] Release build uses production Worker URL (verify in logs after deployment)

---

#### 4.3 Real Device End-to-End Test

**Device**: iPhone 15/16 (recommended) or any iOS 26.1+ device

**Full User Flow**:
1. **First Launch**:
   - [ ] App opens to question card (no onboarding)
   - [ ] Random topic displays
   - [ ] No errors in console

2. **First Recording**:
   - [ ] Tap "Start" → Microphone permission requested
   - [ ] Grant permission
   - [ ] Recording starts, waveform animates
   - [ ] Stop button appears after 10s (DEBUG) or 60s (Release)
   - [ ] Tap "Stop" → Recording completes
   - [ ] Audio playback works

3. **First AI Analysis**:
   - [ ] Tap "Get AI feedback"
   - [ ] "Listening to you..." animation displays
   - [ ] Feedback sheet presents within 45 seconds
   - [ ] All feedback fields populated correctly:
     - Summary (40-60 words)
     - Action tip (≤25 words)
     - Quote extracted from user's speech
     - 4 band scores (Fluency, Lexical Resource, Grammar, Pronunciation)
   - [ ] Scores are in 0.0-9.0 range

4. **Device ID Persistence**:
   - [ ] Close app completely (swipe up from multitasking)
   - [ ] Relaunch app
   - [ ] Complete another recording + analysis
   - [ ] Verify same Device ID used (check Worker logs or iOS console)

5. **Daily Limit Enforcement**:
   - [ ] Complete 10 AI analysis requests (may take 10+ recordings)
   - [ ] 11th request shows error:
     > "That's all for today. Come back tomorrow to continue practicing."
   - [ ] User can still record audio (only AI analysis blocked)
   - [ ] Error dismisses gracefully, no app crash

6. **Privacy Policy Verification**:
   - [ ] Open Settings (if implemented)
   - [ ] Privacy Policy link opens browser
   - [ ] URL: `https://nicheseeker.github.io/IELTSPart2Coach/privacy.html`
   - [ ] Page displays updated content with backend disclosure

---

### 5. Rollback Testing (Optional but Recommended)

**Purpose**: Verify rollback capability if backend fails in production.

#### 5.1 Simulate Backend Failure

**Scenario**: Cloudflare Workers outage or rate limit exceeded

**Test**:
1. Temporarily change Worker URL to invalid endpoint:
   ```swift
   private let baseURL = "https://invalid-worker.example.com"
   ```
2. Build and run app
3. Attempt AI analysis
4. Expected error: "Network connection failed."

**Verification**:
- [ ] App handles failure gracefully
- [ ] User sees error message, not crash
- [ ] Recording is preserved

---

#### 5.2 BYOK Rollback Simulation

**Goal**: Verify preserved BYOK code can be restored quickly

**Steps** (Do NOT commit, just test):
1. Uncomment API Key section in `SettingsView.swift` (line 29)
2. Revert `GeminiService.swift` endpoint to OpenRouter direct:
   ```swift
   private let endpoint = "https://openrouter.ai/api/v1/chat/completions"
   ```
3. Uncomment `makeHeaders()` usage (replace individual headers)
4. Build and run

**Expected Results**:
- [ ] App builds successfully
- [ ] Settings shows "API Key" section
- [ ] User can configure API key
- [ ] AI analysis uses OpenRouter directly (not Worker)

**Rollback Time Estimate**: Should complete in <1 hour

**After Test**: Revert all changes, restore backend proxy mode.

---

## Post-Production Monitoring

### 6. Cloudflare Analytics Dashboard

**Access**: Cloudflare Dashboard → Workers & Pages → Your Worker → Analytics

**Metrics to Monitor** (first 7 days):
- [ ] **Requests**: Should match user AI analysis count (~10-50/day initially)
- [ ] **Success Rate**: Should be >95% (HTTP 200 responses)
- [ ] **Errors**: Monitor 4xx/5xx error spikes
- [ ] **P99 Latency**: Should be <10 seconds for topic generation, <50s for speech analysis
- [ ] **CPU Time**: Should be <10ms (Worker overhead is minimal, most time is OpenRouter API wait)

**Alert Thresholds**:
- Success rate drops below 90% → Investigate Worker logs
- P99 latency exceeds 60s → Check OpenRouter status
- 429 errors spike → Review rate limiting logic

---

### 7. OpenRouter Usage Monitoring

**Access**: OpenRouter Dashboard → Usage

**Metrics to Track**:
- [ ] **Daily Requests**: Should match Cloudflare Worker requests (10-50/day)
- [ ] **Cost**: Monitor credit consumption (Gemini Flash is ~$0.01-0.02 per request)
- [ ] **Rate Limits**: Ensure not hitting OpenRouter's 10 req/min limit
- [ ] **Error Rate**: Should be <5%

**Alert Setup** (if available):
- Credit balance below $5 → Recharge account
- Unexpected spike in requests → Check for abuse

---

### 8. iOS App Store Review Preparation

**Before Submission**:
- [ ] Privacy Policy URL accessible: `https://nicheseeker.github.io/IELTSPart2Coach/privacy.html`
- [ ] All third-party services disclosed:
  - Cloudflare Workers (backend infrastructure)
  - OpenRouter (AI API proxy)
  - Google Gemini (AI model)
- [ ] No hardcoded API keys in app binary (verify with `strings` command)
- [ ] Device ID generation is transparent (mentioned in privacy policy)
- [ ] Daily limit (10 requests) clearly communicated (in error message)

**App Store Connect Metadata**:
- [ ] Privacy labels updated:
  - Data Collected: "Device ID" (Usage Data, Not Linked to User)
  - Purpose: "App Functionality" (rate limiting)
- [ ] Review notes explain backend architecture (Cloudflare Workers proxy)

---

## Completion Checklist

**Before Production Deployment**:
- [ ] All local tests pass (Section 1-2)
- [ ] Worker deployed successfully (Section 3.1-3.3)
- [ ] Production rate limiting verified (Section 3.4)
- [ ] iOS release build tested on real device (Section 4.3)
- [ ] Privacy policy published and accessible (Section 8)
- [ ] OpenRouter API key configured as Worker secret
- [ ] Rollback plan tested and documented (Section 5)

**After Production Deployment**:
- [ ] Monitor Cloudflare Analytics for 24 hours (Section 6)
- [ ] Monitor OpenRouter usage for anomalies (Section 7)
- [ ] Collect user feedback on AI analysis quality
- [ ] Review error logs for unexpected failures

---

## Troubleshooting Quick Reference

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Network timeout in app | Worker not deployed | Run `wrangler deploy` |
| 401 Unauthorized | OPENROUTER_API_KEY not set | `wrangler secret put OPENROUTER_API_KEY` |
| 429 after 1 request | KV binding misconfigured | Check `wrangler.toml` KV namespace ID |
| Invalid response format | Gemini returned non-JSON | Check Worker logs, add error handling |
| Device ID changes on reinstall | Keychain cleared | Expected behavior, explains in docs |
| Audio upload fails | File size >10MB | Add file size validation in iOS |

---

**Document Version**: 1.0
**Created**: 2025-11-22
**Maintainer**: Backend Migration Team
**Related Docs**: BACKEND_MIGRATION_LOG.md, CLOUDFLARE_SETUP_GUIDE.md
