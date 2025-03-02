/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's overall state.
*/

import ARKit
import RealityKit
import RealityKitContent

@MainActor
@Observable
class AppState {
    // シーン
    var scene = Entity()

    // リファレンスオブジェクトローダー
    let referenceObjectLoader = ReferenceObjectLoader()

    // 選択しているアプリ
    var selectionValue = 0

    // デバッグモード
    var debugMode = true

    // イマーシブスペースが閉じたらARKitセッションを停止
    func didLeaveImmersiveSpace() {
        arkitSession.stop()
    }

    // MARK: - ARKit state
    private var arkitSession = ARKitSession()

    private var objectTracking: ObjectTrackingProvider? = nil

    private var handTracking: HandTrackingProvider? = nil

    var objectTrackingStartedRunning = false

    var providersStoppedWithError = false

    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    // ハンドトラッキングを非同期で開始する関数
    func startHandTracking() async -> HandTrackingProvider? {
        // ハンドトラッキングを開始
        let handTracking = HandTrackingProvider()

        // ARKitセッションを開始
        do {
            try await arkitSession.run([handTracking])
        } catch {
            print("DEBUG!: \(error)" )
            return nil
        }

        // 返却
        self.handTracking = handTracking
        return handTracking
    }

    // オブジェクトトラッキングを非同期で開始する関数
    func startTracking() async -> ObjectTrackingProvider? {
        // リファレンスオブジェクトを取得
        let referenceObjects = referenceObjectLoader.enabledReferenceObjects
        guard !referenceObjects.isEmpty else {
            fatalError("No reference objects to start tracking")
        }

        // オブジェクトトラッキングを開始
        let objectTracking = ObjectTrackingProvider(referenceObjects: referenceObjects)

        // ARKitセッションを開始
        do {
            try await arkitSession.run([objectTracking])
        } catch {
            print("DEBUG!: \(error)" )
            return nil
        }

        // 返却
        self.objectTracking = objectTracking
        return objectTracking
    }

    // シーン再構築を非同期で開始する関数
    func startSceneReconstruction() async -> SceneReconstructionProvider? {
        let sceneReconstruction = SceneReconstructionProvider()
        do {
            try await arkitSession.run([sceneReconstruction])
        } catch {
            print("DEBUG!: \(error)")
            return nil
        }

        return sceneReconstruction
    }

    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }

    var allRequiredProvidersAreSupported: Bool {
        ObjectTrackingProvider.isSupported
    }

    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }

    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }

    func queryWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }

    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(let providers, let newState, let error):
                switch newState {
                case .initialized:
                    break
                case .running:
                    guard objectTrackingStartedRunning == false, let objectTracking else { continue }
                    for provider in providers where provider === objectTracking {
                        objectTrackingStartedRunning = true
                        break
                    }
                case .paused:
                    break
                case .stopped:
                    guard objectTrackingStartedRunning == true, let objectTracking else { continue }
                    for provider in providers where provider === objectTracking {
                        objectTrackingStartedRunning = false
                        break
                    }
                    if let error {
                        print("DEBUG!: An error occurred: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                print("DEBUG!: Authorization type \(type) changed to \(status)")
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                }
            default:
                print("DEBUG!: An unknown event occurred \(event)")
            }
        }
    }
}
