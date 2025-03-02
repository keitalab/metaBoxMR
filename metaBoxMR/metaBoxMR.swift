import SwiftUI

@main
struct metaBoxMR: App {

    @State private var appState = AppState()

    var body: some Scene {
        ImmersiveSpace(id: "ObjectTracking") {
            ObjectTrackingRealityView(appState: appState)
        }
    }
}
