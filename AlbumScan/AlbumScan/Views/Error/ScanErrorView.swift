import SwiftUI

struct ScanErrorView: View {
    let onRetry: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.red)

            Text("Couldn't find a match")
                .font(.title2)
                .fontWeight(.bold)

            Text("Try taking another photo with better lighting or a clearer view of the album cover.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                dismiss()
                onRetry()
            }) {
                Text("TRY AGAIN")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

struct ScanErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ScanErrorView(onRetry: {})
    }
}
