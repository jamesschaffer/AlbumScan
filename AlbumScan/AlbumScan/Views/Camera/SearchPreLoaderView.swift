import SwiftUI

enum LoadingStage: Int, CaseIterable {
    case callingAPI = 0
    case parsingResponse = 1
    case downloadingArtwork = 2

    var text: String {
        switch self {
        case .callingAPI:
            return "Flipping through every record bin in existence"
        case .parsingResponse:
            return "Writing a review that's somehow both pretentious and correct"
        case .downloadingArtwork:
            return "Hunting down cover art worthy of your screen"
        }
    }
}

struct SearchPreLoaderView: View {
    @Binding var currentStage: LoadingStage
    @State private var dotCount: Int = 0
    @State private var displayedStage: LoadingStage = .callingAPI
    @State private var stageStartTime: Date = Date()
    @State private var dotTimer: Timer?

    let greenColor = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Full black background
            Color.black
                .ignoresSafeArea()

            // Stage text with animated dots
            VStack(alignment: .leading, spacing: 0) {
                (Text(displayedStage.text)
                    .foregroundColor(.white) +
                 Text(String(repeating: ".", count: dotCount))
                    .foregroundColor(greenColor))
                    .font(.system(size: 28))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 30)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
            .id(displayedStage.rawValue) // Force view recreation on stage change
        }
        .onAppear {
            startDotAnimation()
        }
        .onChange(of: currentStage) { newStage in
            advanceToStage(newStage)
        }
    }

    private func startDotAnimation() {
        // Start immediately with first dot
        dotCount = 1

        // Cancel any existing timer
        dotTimer?.invalidate()

        // Create new timer on main run loop
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            dotCount = (dotCount % 3) + 1 // Cycles 1, 2, 3, 1...
        }

        // Ensure timer runs during UI updates
        if let timer = dotTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func advanceToStage(_ newStage: LoadingStage) {
        // Enforce minimum 1-second display time before advancing
        let timeElapsed = Date().timeIntervalSince(stageStartTime)
        let minimumDisplayTime: TimeInterval = 1.0

        if timeElapsed < minimumDisplayTime {
            // Wait for remaining time before advancing
            let remainingTime = minimumDisplayTime - timeElapsed
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                self.performStageTransition(to: newStage)
            }
        } else {
            // Enough time has passed, advance immediately
            performStageTransition(to: newStage)
        }
    }

    private func performStageTransition(to newStage: LoadingStage) {
        withAnimation(.easeOut(duration: 0.35)) {
            displayedStage = newStage
        }
        stageStartTime = Date()
    }
}

struct SearchPreLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        SearchPreLoaderView(currentStage: .constant(.callingAPI))
    }
}
