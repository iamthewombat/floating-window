import SwiftUI

protocol FloatingExtension: ObservableObject, Identifiable {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get } // SF Symbol name
    var isEnabled: Bool { get set }
    var preferredSize: CGSize { get }

    associatedtype ContentView: View
    @MainActor @ViewBuilder func makeView() -> ContentView
}
