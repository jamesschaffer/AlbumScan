# Gemini Integration Implementation Plan

**Version:** 1.0
**Date:** December 7, 2025
**Objective:** Implement user-facing toggle to switch between ChatGPT (OpenAI) and Gemini providers

---

## Executive Summary

This plan enables **runtime provider selection** between OpenAI ("ChatGPT") and Gemini while maintaining the existing architecture's integrity. The implementation leverages the existing `LLMService` protocol abstraction and `LLMServiceFactory` pattern, requiring minimal changes to the app's business logic.

---

## Architecture Overview

### Current State
```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   CameraManager │────▶│  LLMServiceFactory   │────▶│  CloudFunctionsService │
│  (orchestrator) │     │  (static selection)  │     │  (OpenAI via Firebase) │
└─────────────────┘     └──────────────────────┘     └─────────────────────────┘
                                │
                        Config.currentProvider
                         (compile-time constant)
```

### Target State
```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   CameraManager │────▶│  LLMServiceFactory   │────▶│  CloudFunctionsService │
│  (orchestrator) │     │  (dynamic selection) │     │  (OpenAI OR Gemini)    │
└─────────────────┘     └──────────────────────┘     └─────────────────────────┘
                                │
                         AppState.selectedProvider
                          (runtime UserDefaults)
                                │
                        ┌───────┴───────┐
                        ▼               ▼
               identifyAlbum     identifyAlbumGemini
               (OpenAI)          (Gemini)
```

---

## Implementation Phases

### Phase 1: Backend - Cloud Functions (Gemini Support)
**Estimated Effort:** Medium
**Risk Level:** Low (additive, non-breaking)

#### 1.1 Add Gemini Secret to Firebase
```bash
# Store Gemini API key in Firebase Secrets Manager
firebase functions:secrets:set GEMINI_API_KEY
```

#### 1.2 Update `functions/src/index.ts`

**New imports and secrets:**
```typescript
import { GoogleGenerativeAI } from "@google/generative-ai";

const geminiKey = defineSecret("GEMINI_API_KEY");
```

**New Gemini functions (parallel to OpenAI):**

| Function | Purpose | Gemini Model |
|----------|---------|--------------|
| `identifyAlbumGemini` | ID Call 1 (vision) | gemini-2.5-flash |
| `searchFinalizeAlbumGemini` | ID Call 2 (search) | gemini-2.5-flash + googleSearch tool |
| `generateReviewGemini` | Review generation | gemini-2.5-flash (± googleSearch) |

**Example implementation structure:**
```typescript
// ============================================================================
// GEMINI: ID CALL 1 - Single-Prompt Identification
// ============================================================================

export const identifyAlbumGemini = onCall(
  {
    secrets: [geminiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<IdentificationRequest>) => {
    const deviceId = getDeviceId(request);

    if (!checkRateLimit(deviceId)) {
      throw new HttpsError("resource-exhausted", "Too many requests.");
    }

    const { base64Image, prompt } = request.data;

    if (!base64Image || !prompt) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    try {
      const genAI = new GoogleGenerativeAI(geminiKey.value());
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        generationConfig: {
          responseMimeType: "application/json"
        }
      });

      const result = await model.generateContent({
        contents: [{
          parts: [
            { text: prompt },
            { inlineData: { mimeType: "image/jpeg", data: base64Image } }
          ]
        }]
      });

      const response = result.response;
      const text = response.text();

      console.log(`[identifyAlbumGemini] Response received from device: ${deviceId}`);

      return {
        success: true,
        data: {
          choices: [{
            message: { content: text }
          }]
        }
      };
    } catch (error) {
      console.error("[identifyAlbumGemini] Error:", error);
      throw new HttpsError("internal", "Failed to process image.");
    }
  }
);

// ============================================================================
// GEMINI: ID CALL 2 - Search Finalization (with Google Search grounding)
// ============================================================================

export const searchFinalizeAlbumGemini = onCall(
  {
    secrets: [geminiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<SearchFinalizationRequest>) => {
    const deviceId = getDeviceId(request);

    if (!checkRateLimit(deviceId)) {
      throw new HttpsError("resource-exhausted", "Too many requests.");
    }

    const { prompt } = request.data;

    if (!prompt) {
      throw new HttpsError("invalid-argument", "Missing required field: prompt");
    }

    try {
      const genAI = new GoogleGenerativeAI(geminiKey.value());
      const model = genAI.getGenerativeModel({
        model: "gemini-2.5-flash",
        tools: [{ googleSearch: {} }]  // Enable search grounding
      });

      const result = await model.generateContent(prompt);
      const response = result.response;
      const text = response.text();

      // Log grounding metadata if available
      const groundingMetadata = response.candidates?.[0]?.groundingMetadata;
      if (groundingMetadata) {
        console.log(`[searchFinalizeAlbumGemini] Search queries: ${
          groundingMetadata.webSearchQueries?.join(", ")
        }`);
      }

      return {
        success: true,
        data: {
          choices: [{
            message: { content: text }
          }]
        }
      };
    } catch (error) {
      console.error("[searchFinalizeAlbumGemini] Error:", error);
      throw new HttpsError("internal", "Failed to search.");
    }
  }
);

// ============================================================================
// GEMINI: Review Generation
// ============================================================================

export const generateReviewGemini = onCall(
  {
    secrets: [geminiKey],
    enforceAppCheck: true,
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (request: CallableRequest<ReviewRequest>) => {
    const deviceId = getDeviceId(request);

    if (!checkRateLimit(deviceId)) {
      throw new HttpsError("resource-exhausted", "Too many requests.");
    }

    const { prompt, useSearch = false } = request.data;

    if (!prompt) {
      throw new HttpsError("invalid-argument", "Missing required field: prompt");
    }

    try {
      const genAI = new GoogleGenerativeAI(geminiKey.value());

      // Configure model with or without search based on Ultra tier
      const modelConfig: any = { model: "gemini-2.5-flash" };
      if (useSearch) {
        modelConfig.tools = [{ googleSearch: {} }];
      }

      const model = genAI.getGenerativeModel(modelConfig);
      const result = await model.generateContent(prompt);
      const text = result.response.text();

      console.log(`[generateReviewGemini] Review generated for device: ${deviceId}`);

      return {
        success: true,
        data: {
          choices: [{
            message: { content: text }
          }]
        }
      };
    } catch (error) {
      console.error("[generateReviewGemini] Error:", error);
      throw new HttpsError("internal", "Failed to generate review.");
    }
  }
);
```

#### 1.3 Update `package.json` Dependencies
```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google/generative-ai": "^0.21.0"
  }
}
```

#### 1.4 Deploy Cloud Functions
```bash
cd functions
npm install @google/generative-ai
npm run build
firebase deploy --only functions
```

---

### Phase 2: iOS - Provider Enum & Config Updates
**Estimated Effort:** Low
**Risk Level:** Low

#### 2.1 Update `Config.swift` - Add Gemini Provider

```swift
// MARK: - LLM Provider Selection

enum LLMProvider: String, CaseIterable {
    case openAI = "openai"
    case gemini = "gemini"

    // Legacy providers (not user-selectable)
    case claude = "claude"
    case cloudFunctions = "cloudFunctions"  // Deprecated - use openAI/gemini

    var displayName: String {
        switch self {
        case .openAI: return "ChatGPT"
        case .gemini: return "Gemini"
        case .claude: return "Claude"
        case .cloudFunctions: return "Cloud Functions"
        }
    }

    var description: String {
        switch self {
        case .openAI: return "OpenAI GPT-4o"
        case .gemini: return "Google Gemini 2.5 Flash"
        case .claude: return "Anthropic Claude (Legacy)"
        case .cloudFunctions: return "Firebase Proxy (Legacy)"
        }
    }

    /// User-selectable providers for the toggle
    static var selectableProviders: [LLMProvider] {
        [.openAI, .gemini]
    }
}
```

#### 2.2 Update `Config.swift` - Add UserDefaults Key

```swift
enum UserDefaultsKeys {
    static let hasLaunchedBefore = "hasLaunchedBefore"
    static let selectedLLMProvider = "selectedLLMProvider"  // NEW
}
```

---

### Phase 3: iOS - AppState Provider Management
**Estimated Effort:** Low
**Risk Level:** Low

#### 3.1 Update `AppState.swift`

```swift
class AppState: ObservableObject {
    // ... existing properties ...

    // MARK: - AI Provider Selection (Beta)

    @Published var selectedProvider: LLMProvider {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: Config.UserDefaultsKeys.selectedLLMProvider)
            #if DEBUG
            print("🤖 [Provider] Changed to: \(selectedProvider.displayName)")
            #endif
        }
    }

    init() {
        // ... existing init code ...

        // Load saved provider preference (default to OpenAI for existing users)
        if let savedProvider = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.selectedLLMProvider),
           let provider = LLMProvider(rawValue: savedProvider) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .openAI  // Default for new users
        }

        #if DEBUG
        print("🤖 [Provider] Loaded: \(selectedProvider.displayName)")
        #endif
    }
}
```

---

### Phase 4: iOS - CloudFunctionsService Provider Routing
**Estimated Effort:** Medium
**Risk Level:** Medium (core business logic)

#### 4.1 Update `CloudFunctionsService.swift`

Add provider parameter to all API calls:

```swift
class CloudFunctionsService: LLMService {
    static let shared = CloudFunctionsService()

    private let functions: Functions

    // ... existing prompt storage ...

    // MARK: - Provider-Aware Function Names

    private func functionName(_ baseName: String, provider: LLMProvider) -> String {
        switch provider {
        case .gemini:
            return "\(baseName)Gemini"
        case .openAI, .cloudFunctions:
            return baseName
        case .claude:
            fatalError("Claude is not supported via Cloud Functions")
        }
    }

    // MARK: - Single-Prompt Identification (Call 1)

    func executeSinglePromptIdentification(image: UIImage, provider: LLMProvider = .openAI) async throws -> AlbumIdentificationResponse {
        #if DEBUG
        print("🔍 [CloudFunctions ID Call 1] Provider: \(provider.displayName)")
        #endif

        guard let base64Image = convertImageToBase64(image) else {
            throw APIError.imageProcessingFailed
        }

        let data: [String: Any] = [
            "base64Image": base64Image,
            "prompt": identificationPrompt
        ]

        let fnName = functionName("identifyAlbum", provider: provider)

        #if DEBUG
        print("📡 [CloudFunctions] Calling \(fnName)...")
        #endif

        do {
            let result = try await functions.httpsCallable(fnName).call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success,
                  let responseData = resultData["data"] as? [String: Any] else {
                throw APIError.invalidResponse
            }

            return try parseIdentificationResponse(from: responseData)

        } catch let error as NSError {
            // ... existing error handling ...
        }
    }

    // Similar updates for executeSearchFinalization and generateReviewPhase2...
}
```

#### 4.2 Update `LLMService.swift` Protocol (Optional)

If you want provider awareness at the protocol level:

```swift
protocol LLMService {
    func executeSinglePromptIdentification(image: UIImage, provider: LLMProvider) async throws -> AlbumIdentificationResponse
    func executeSearchFinalization(image: UIImage, searchRequest: SearchRequest, provider: LLMProvider) async throws -> AlbumIdentificationResponse
    func generateReviewPhase2(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: [String],
        recordLabel: String,
        searchEnabled: Bool,
        provider: LLMProvider
    ) async throws -> Phase2Response
}
```

**Alternative (Recommended):** Keep the protocol unchanged and inject provider via `LLMServiceFactory`:

```swift
class LLMServiceFactory {
    static func getService(for provider: LLMProvider) -> LLMService {
        // All providers now route through CloudFunctionsService
        // which handles the provider routing internally
        return CloudFunctionsService.shared
    }
}
```

---

### Phase 5: iOS - CameraManager Integration
**Estimated Effort:** Low
**Risk Level:** Medium

#### 5.1 Update `CameraManager.swift`

Inject provider from AppState into all LLM calls:

```swift
class CameraManager: NSObject, ObservableObject {
    // ... existing properties ...

    // Reference to AppState for provider selection
    private var appState: AppState?

    func configure(with appState: AppState) {
        self.appState = appState
    }

    // In scan methods, pass provider:
    private func performIdentification(image: UIImage) async throws -> AlbumIdentificationResponse {
        let provider = appState?.selectedProvider ?? .openAI

        #if DEBUG
        print("🔍 [CameraManager] Using provider: \(provider.displayName)")
        #endif

        let service = LLMServiceFactory.getService(for: provider)
        return try await service.executeSinglePromptIdentification(image: image, provider: provider)
    }
}
```

---

### Phase 6: iOS - Settings UI Toggle
**Estimated Effort:** Medium
**Risk Level:** Low

#### 6.1 Create `AIProviderToggle.swift` View Component

```swift
import SwiftUI

struct AIProviderToggle: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("AI Engine")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Beta badge
                Text("BETA")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }

            // Provider selection
            HStack(spacing: 12) {
                ForEach(LLMProvider.selectableProviders, id: \.self) { provider in
                    ProviderButton(
                        provider: provider,
                        isSelected: appState.selectedProvider == provider,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.selectedProvider = provider
                            }
                        }
                    )
                }
            }

            // Description
            Text(appState.selectedProvider.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct ProviderButton: View {
    let provider: LLMProvider
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: providerIcon)
                    .font(.system(size: 16))
                Text(provider.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var providerIcon: String {
        switch provider {
        case .openAI: return "bubble.left.fill"
        case .gemini: return "sparkles"
        default: return "cpu"
        }
    }
}
```

#### 6.2 Integrate into `SettingsView.swift`

```swift
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    // ... existing properties ...

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                // NEW: AI Provider Toggle (Beta)
                AIProviderToggle()
                    .padding(.horizontal, 20)

                // Existing subscription card
                SubscriptionCardView(/* ... */)
                    .padding(24)
                    // ...
            }
        }
    }
}
```

---

## Phase 7: Testing & Validation

### 7.1 Unit Tests

| Test Case | Provider | Expected Behavior |
|-----------|----------|-------------------|
| ID Call 1 - Famous Album | OpenAI | Returns correct album, confidence: high |
| ID Call 1 - Famous Album | Gemini | Returns correct album, confidence: high |
| ID Call 1 - Obscure Album | OpenAI | Returns searchNeeded: true |
| ID Call 1 - Obscure Album | Gemini | Returns searchNeeded: true |
| ID Call 2 - With Search | OpenAI | Returns correct album with search |
| ID Call 2 - With Search | Gemini | Returns correct album with grounding |
| Review - Non-Ultra | OpenAI | Returns review without citations |
| Review - Non-Ultra | Gemini | Returns review without grounding |
| Review - Ultra | OpenAI | Returns review (search model) |
| Review - Ultra | Gemini | Returns review with grounding metadata |

### 7.2 Integration Tests

```swift
// Test provider switching mid-session
func testProviderSwitchingPreservesState() async {
    // 1. Scan album with OpenAI
    appState.selectedProvider = .openAI
    let result1 = try await scanAlbum(testImage)

    // 2. Switch to Gemini
    appState.selectedProvider = .gemini

    // 3. Verify history still accessible
    XCTAssertFalse(historyManager.albums.isEmpty)

    // 4. Scan same album with Gemini
    let result2 = try await scanAlbum(testImage)

    // 5. Verify both results match
    XCTAssertEqual(result1.albumTitle, result2.albumTitle)
}
```

### 7.3 A/B Testing Metrics

Track these metrics per provider during beta:

| Metric | Description |
|--------|-------------|
| `identification_success_rate` | % of scans that return success=true |
| `search_escalation_rate` | % of scans requiring ID Call 2 |
| `review_cache_hit_rate` | % of reviews served from cache |
| `avg_response_time_ms` | Average latency per call type |
| `user_provider_preference` | Which provider users select |
| `provider_switch_frequency` | How often users change providers |

---

## Phase 8: Rollout Strategy

### 8.1 Beta Release (Internal)

1. Deploy Cloud Functions with Gemini support
2. Release TestFlight build with toggle (hidden behind debug flag initially)
3. Internal team testing for 1 week
4. Collect feedback on quality parity

### 8.2 Beta Release (Public)

1. Enable toggle for all TestFlight users
2. Default new users to OpenAI (familiar behavior)
3. Monitor metrics for 2 weeks
4. Iterate on prompt adjustments if needed

### 8.3 Production Release

1. Ship to App Store with toggle visible
2. Include in-app messaging: "Try our new Gemini AI engine (Beta)"
3. Monitor for 30 days
4. Decide on default provider based on data

---

## Future Considerations (Post-Beta)

### Permanent Migration Path

If Gemini proves superior, the toggle can be removed:

```swift
// Config.swift - Future state
enum Config {
    /// Set to true to hide provider toggle and use Gemini exclusively
    static let geminiOnlyMode = true

    static var defaultProvider: LLMProvider {
        geminiOnlyMode ? .gemini : .openAI
    }
}
```

### Cost Tracking

Add provider dimension to cost logging:

```typescript
console.log(JSON.stringify({
  event: "api_call",
  provider: "gemini",
  function: "identifyAlbum",
  tokens_in: 258,
  tokens_out: 450,
  cost_estimate: 0.0003
}));
```

### Fallback Strategy

If one provider has an outage:

```swift
func executeSinglePromptIdentification(image: UIImage) async throws -> AlbumIdentificationResponse {
    let primaryProvider = appState.selectedProvider

    do {
        return try await callProvider(primaryProvider, image: image)
    } catch {
        #if DEBUG
        print("⚠️ Primary provider failed, trying fallback...")
        #endif

        let fallbackProvider: LLMProvider = primaryProvider == .openAI ? .gemini : .openAI
        return try await callProvider(fallbackProvider, image: image)
    }
}
```

---

## File Change Summary

| File | Changes |
|------|---------|
| `functions/src/index.ts` | Add 3 Gemini functions |
| `functions/package.json` | Add `@google/generative-ai` |
| `Config.swift` | Update `LLMProvider` enum, add UserDefaults key |
| `AppState.swift` | Add `selectedProvider` property |
| `CloudFunctionsService.swift` | Add provider routing logic |
| `LLMServiceFactory.swift` | Update to accept provider parameter |
| `CameraManager.swift` | Inject provider into LLM calls |
| `SettingsView.swift` | Add `AIProviderToggle` component |
| `AIProviderToggle.swift` | NEW: Provider toggle UI component |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gemini response format differs | Medium | Medium | Normalize in Cloud Functions before returning |
| Gemini quality lower than OpenAI | Low | High | Extensive testing, easy toggle back |
| User confusion with toggle | Low | Low | Clear labeling, "Beta" badge |
| Increased backend complexity | Medium | Low | Shared rate limiting, common response format |
| Gemini API changes | Low | Medium | Abstract in Cloud Functions layer |

---

**Last Updated:** December 7, 2025
**Author:** Technical Architecture Review
