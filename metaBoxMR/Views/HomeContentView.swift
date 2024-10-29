//
//  ContentView.swift
//  VisionOSObjectTrackingDemo
//
//  Created by Dilmer Valecillos on 7/6/24.
//

import SwiftUI
import RealityKit

struct HomeContentView: View {
    let immersiveSpaceIdentifier: String
    @Bindable var appState: AppState
   
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        TabView {
            VStack(spacing: 20) {
                Group {
                    Text("metaBoxMR")
                        .font(.system(size: 24, weight:. bold))
                }
                VStack {
                    if appState.canEnterImmersiveSpace {
                        VStack {
                            if !appState.isImmersiveSpaceOpened {
                                Button("トラッキングを開始") {
                                    Task {
                                        switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                        case .opened:
                                            break
                                        case .error:
                                            print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                        case .userCancelled:
                                            print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                        @unknown default:
                                            break
                                        }
                                    }
                                }
                                .disabled(!appState.canEnterImmersiveSpace || appState.referenceObjectLoader.enabledReferenceObjectsCount == 0)
                            } else {
                                Button("トラッキングを終了") {
                                    Task {
                                        await dismissImmersiveSpace()
                                        appState.didLeaveImmersiveSpace()
                                    }
                                }
                                
                                if !appState.objectTrackingStartedRunning {
                                    HStack {
                                        ProgressView()
                                        Text("Please wait until all reference objects have been loaded")
                                    }
                                }
                            }
                            
                            Text(appState.isImmersiveSpaceOpened ?
                                 "This leaves the immersive space." :
                                 "This enters an immersive space, hiding all other apps."
                            )
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .padding(.horizontal)
                        }
                    }
                }
                .onChange(of: scenePhase, initial: true) {
                    print("Scene phase: \(scenePhase)")
                    if scenePhase == .active {
                        Task {
                            // When returning from the background, check if the authorization has changed.
                            await appState.queryWorldSensingAuthorization()
                        }
                    } else {
                        // Make sure to leave the immersive space if this view is no longer active
                        // - such as when a person closes this view - otherwise they may be stuck
                        // in the immersive space without the controls this view provides.
                        if appState.isImmersiveSpaceOpened {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                            }
                        }
                    }
                }
                .onChange(of: appState.providersStoppedWithError, { _, providersStoppedWithError in
                    // Immediately close the immersive space if an error occurs.
                    if providersStoppedWithError {
                        if appState.isImmersiveSpaceOpened {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                            }
                        }
                        
                        appState.providersStoppedWithError = false
                    }
                })
                .task {
                    // Ask for authorization before a person attempts to open the immersive space.
                    // This gives the app opportunity to respond gracefully if authorization isn't granted.
                    if appState.allRequiredProvidersAreSupported {
                        await appState.requestWorldSensingAuthorization()
                    }
                }
                .task {
                    // Start monitoring for changes in authorization, in case a person brings the
                    // Settings app to the foreground and changes authorizations there.
                    await appState.monitorSessionEvents()
                }
            }.tabItem {
                Label("Tracking", systemImage: "plus.viewfinder")
            }.tag(0)
            
            VStack {
                VStack(spacing: 20) {
                    Text("アプリを選択")
                        .font(.system(size: 24, weight:. bold))
                    Picker("選択", selection: $appState.selectionValue) {
                        ForEach(0..<metaBoxApps.count, id: \.self) { index in
                            Text(metaBoxApps[index].name).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }

            }.tabItem {
                Label("Apps", systemImage: "gear")
            }.tag(1)
        }
    }
    
    struct HomeContentView_Previews: PreviewProvider {
        static var previews: some View {
            HomeContentView(immersiveSpaceIdentifier: "ObjectTracking", appState: AppState())
        }
    }
}

#Preview(windowStyle: .automatic) {
    HomeContentView(immersiveSpaceIdentifier: "ObjectTracking", appState: AppState())
}
