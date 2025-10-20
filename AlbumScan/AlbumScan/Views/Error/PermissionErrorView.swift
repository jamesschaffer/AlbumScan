import SwiftUI

struct PermissionErrorView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "camera.fill.badge.exclamationmark")
                .font(.system(size: 70))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("Camera Access Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("AlbumScan needs access to your camera to identify album covers.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
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

struct PermissionErrorView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionErrorView()
    }
}
