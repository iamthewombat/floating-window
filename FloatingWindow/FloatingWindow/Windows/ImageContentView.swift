import SwiftUI

struct ImageContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                if let image = appState.currentImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: appState.aspectMode == .fill ? .fill : .fit)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No image selected")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Use the menu bar icon to choose a folder or paste an image")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}
