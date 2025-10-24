import Foundation

/// Represents the current state of the album scanning process
/// Used to manage UI transitions through the two-tier API architecture
enum ScanState {
    case idle                    // Camera view, ready to scan
    case identifying             // Phase 1 in progress (2-4 seconds)
    case identified              // Phase 1 success, brief transition (0.5s)
    case loadingReview           // Phase 2 + artwork in progress (3-6 seconds)
    case complete                // Both phases done, displaying results
    case identificationFailed    // Phase 1 failed (show error screen)
    case reviewFailed            // Phase 1 worked, Phase 2 failed (partial results)

    /// Whether the scan is currently in progress
    var isProcessing: Bool {
        switch self {
        case .identifying, .identified, .loadingReview:
            return true
        case .idle, .complete, .identificationFailed, .reviewFailed:
            return false
        }
    }

    /// Whether we should show a loading indicator
    var isLoading: Bool {
        switch self {
        case .identifying, .loadingReview:
            return true
        case .idle, .identified, .complete, .identificationFailed, .reviewFailed:
            return false
        }
    }

    /// User-facing description of current state
    var description: String {
        switch self {
        case .idle:
            return "Ready to scan"
        case .identifying:
            return "Identifying album..."
        case .identified:
            return "Album identified"
        case .loadingReview:
            return "Loading review..."
        case .complete:
            return "Complete"
        case .identificationFailed:
            return "Identification failed"
        case .reviewFailed:
            return "Review unavailable"
        }
    }
}
