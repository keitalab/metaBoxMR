/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view shown inside the immersive space.
*/

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

@MainActor
struct ObjectTrackingRealityView: View {
    // 共通
    @Bindable var appState: AppState
    @State private var currentAppClass: AppClass
    @State private var currentAppView: AnyView

    @State private var timer: Timer?

    @State private var isTaskRunning = false


    init(appState: AppState) {
        self.appState = appState
        self._currentAppClass = State(initialValue: metaBoxApps[appState.selectionValue].appClass)
        self._currentAppView  = State(initialValue: metaBoxApps[appState.selectionValue].appView)
    }

    // ハンドトラッキング用の指先エンティティを作成
    func createJointEntity() -> ModelEntity {
        // 関節部のエンティティを作成
        let jointEntity = ModelEntity(
            mesh: .generateBox(size: [0.01, 0.01, 0.01]),
            materials: [SimpleMaterial(color: .green, isMetallic: false)]
        )

        // Materialを作成
        var material = UnlitMaterial(color: .green)

        if appState.debugMode {
            material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.2))
        } else {
            material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.0))
        }

        // 判定用に名前をつける
        jointEntity.name = "handJoint"

        // Collisionを追加
        jointEntity.components.set(
            CollisionComponent(
                shapes: [.generateBox(size: [0.01, 0.01, 0.01])],
                mode: .default
            )
        )

        // Materialを設定
        jointEntity.model?.materials = [material]

        return jointEntity
    }

    // ハンドトラッキング用のジョイント
    let handJoints: Array<AnchoringComponent.Target.HandLocation.HandJoint> = [
//        .forearmArm,
//        .forearmWrist,
        .indexFingerIntermediateBase,
//        .indexFingerTip,
//        .indexFingerKnuckle,
//        .indexFingerMetacarpal,
//        .indexFingerIntermediateTip,
        .middleFingerIntermediateBase,
//        .middleFingerTip,
//        .middleFingerKnuckle,
//        .middleFingerMetacarpal,
//        .middleFingerIntermediateTip,
//        .ringFingerIntermediateBase,
//        .ringFingerTip,
//        .ringFingerKnuckle,
//        .ringFingerMetacarpal,
//        .ringFingerIntermediateTip,
//        .littleFingerIntermediateBase,
//        .littleFingerTip,
//        .littleFingerKnuckle,
//        .littleFingerMetacarpal,
//        .littleFingerIntermediateTip,
//        .thumbIntermediateBase,
//        .thumbKnuckle,
//        .thumbIntermediateTip,
        .thumbTip,
        .wrist
    ]

    // ハンドトラッキング用のジョイント名
    func handJointName(for joint: AnchoringComponent.Target.HandLocation.HandJoint) -> String {
        switch joint {
        case .indexFingerTip: return "indexFingerTip"
        case .indexFingerIntermediateBase: return "indexFingerIntermediateBase"
        case .middleFingerTip: return "middleFingerTip"
        case .middleFingerIntermediateBase: return "middleFingerIntermediateBase"
        case .ringFingerTip: return "ringFingerTip"
        case .littleFingerTip: return "littleFingerTip"
        case .thumbTip: return "thumbTip"
        case .wrist: return "wrist"
        // 他のジョイントも必要に応じて追加
        default: return "unknownJoint"
        }
    }

    // ハンドジョイントを削除
    func removeHandJointEntities(from scene: Entity) {
        for child in appState.scene.children {
            // "HandJoint"を含む名前のエンティティを削除
            if child.name.contains("HandJoint") {
                child.removeFromParent()
            } else {
                // 子エンティティも再帰的に探索
                removeHandJointEntities(from: child)
            }
        }
    }

    // ジオメトリからModelEntityを生成
    @MainActor
    func generateModelEntity(geometry: MeshAnchor.Geometry) async throws -> ModelEntity {
        // MeshDescriptorを作成
        var desc = MeshDescriptor()

        // 頂点情報を設定
        let posValues = geometry.vertices.asSIMD3(ofType: Float.self)
        desc.positions = .init(posValues)

        // 法線情報を設定
        let normalValues = geometry.normals.asSIMD3(ofType: Float.self)
        desc.normals = .init(normalValues)

        // 各面（ポリゴン）の情報を設定（ここでは全て三角形と仮定）
        desc.primitives = .polygons(
            (0..<geometry.faces.count).map { _ in UInt8(3) },
            (0..<geometry.faces.count * 3).map {
                geometry.faces.buffer.contents()
                    .advanced(by: $0 * geometry.faces.bytesPerIndex)
                    .assumingMemoryBound(to: UInt32.self).pointee
            }
        )

        // MeshResourceを生成
        let meshResource = try MeshResource.generate(from: [desc])

        // マテリアルを作成
        let geometryMaterial: RealityKit.Material = {
            if appState.debugMode {
                var _material = UnlitMaterial(color: .blue)
                _material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.2))
                return _material
            } else {
//                return OcclusionMaterial()

                var _material = UnlitMaterial(color: .blue)
                _material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.0))
                return _material
            }
        }()

        // MeshResourceとマテリアルからModelEntityを生成
        let modelEntity = ModelEntity(mesh: meshResource, materials: [geometryMaterial])
        return modelEntity
    }

    // オブジェクトトラッキング用のアンカーエンティティ
    @State private var objectAnchors: [UUID: ObjectAnchorEntity] = [:]

    // シーン検出用のアンカーエンティティ
    @State private var meshEntities = [UUID: ModelEntity]()

    var body: some View {
        RealityView { content, attachments in
            content.add(appState.scene)  // シーンを追加

            Task {
                // ----- ハンドトラッキングの処理 ----- //

                // ハンドトラッキングを開始
                let session = SpatialTrackingSession()
                let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])

                if let unavailableCapabilities = await session.run(configuration) {
                    if unavailableCapabilities.anchor.contains(.hand) {
                        print("DEBUG!: The device doesn't support plane tracking.")
                    }
                } else {
                    // 左右の手に対して各ジョイント分のAnchorEntityを生成
                    for chirality in [AnchoringComponent.Target.Chirality.left, .right] {
                        for handjoint in handJoints {
                            // ジョイントエンティティを生成
                            let copyJointEntity = createJointEntity().clone(recursive: true)
                            copyJointEntity.name = "HandJoint:\(chirality == .left ? "Left" : "Right")_\(handJointName(for: handjoint))"

                            // 特定のジョイントに対してエンティティのサイズを拡大
                            if handjoint == .wrist || handjoint == .forearmArm || handjoint == .forearmWrist {
                                copyJointEntity.scale *= 5.0
                            }

                            // ハンドジョイントに対して固定
                            let joint = AnchoringComponent.Target.HandLocation.joint(for: handjoint)

                            // アンカーエンティティを生成
                            let anchorEntity = AnchorEntity(.hand(chirality, location: joint), trackingMode: .predicted)

                            // 物理シミュレーションを無効にする
                            var anchorComponent = anchorEntity.components[AnchoringComponent.self]!
                            anchorComponent.physicsSimulation = .none
                            anchorEntity.components.set(anchorComponent)

                            // ジョイントエンティティをアンカーエンティティに追加
                            anchorEntity.addChild(copyJointEntity)

                            // シーンに追加
                            appState.scene.addChild(anchorEntity)
                        }
                    }
                }
            }

            Task {
                // ----- オブジェクトトラッキングの処理 ----- //
                // リファレンスオブジェクトが読み込まれていない場合のみ読み込みを実行
                if appState.referenceObjectLoader.referenceObjects.isEmpty {
                    await appState.referenceObjectLoader.loadBuiltInReferenceObjects()
                }

                // オブジェクトトラッキングを開始
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }

                // アンカー更新時に非同期で実行
                for await update in objectTracking.anchorUpdates {
                    // アンカーを更新
                    let anchor = update.anchor
                    // アンカーIDを取得
                    let id = anchor.id

                    // イベント
                    switch update.event {
                    // 追加時
                    case .added:
                        // RefObjectの3Dmodelを取得
                        let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let anchorEntity = ObjectAnchorEntity(for: anchor, withModel: model)
                        self.objectAnchors[id] = anchorEntity
                        appState.scene.addChild(anchorEntity.entity)

                        // Attachment1
                        if let attachmentEntity = attachments.entity(for: "attachment1") {
                            attachmentEntity.position = [0.16, 0.18, 0]
                            attachmentEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: SIMD3<Float>(0,1,0))
                            anchorEntity.entity.addChild(attachmentEntity)
                        } else {
                            print("DEBUG!: Attachment entity not found for ID: attachment1")
                        }

                        // Attachment2
                        if let attachmentEntity = attachments.entity(for: "attachment2") {
                            attachmentEntity.position = [0.16, 0.18, -0.3]
                            attachmentEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: SIMD3<Float>(0,1,0))
                            anchorEntity.entity.addChild(attachmentEntity)
                        } else {
                            print("DEBUG!: Attachment entity not found for ID: attachment2")
                        }

                        // オブジェクトトラッキング用にエンティティを追加
                        await currentAppClass.addSkinEntity(anchorEntity: anchorEntity)
                        await currentAppClass.addEntityForObjectTracking(anchorEntity: anchorEntity)

                    // 更新時
                    case .updated:
                        self.objectAnchors[id]?.update(with: anchor)

                    // 削除時
                    case .removed:
                        self.objectAnchors[id]?.entity.removeFromParent()
                        self.objectAnchors.removeValue(forKey: id)
                    }
                }
            }

            Task {
                // ----- シーン検出 ----- //

                // シーン検出を開始
                let sceneReconstruction = await appState.startSceneReconstruction()
                guard let sceneReconstruction else {
                    return
                }

                // アンカー更新時に非同期で実行
                for await update in sceneReconstruction.anchorUpdates {
                    let meshAnchor = update.anchor

                    // イベント
                    switch update.event {
                    // 追加時
                    case .added:
                        let modelEntity = try await generateModelEntity(geometry: meshAnchor.geometry)
                        modelEntity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)

                        meshEntities[meshAnchor.id] = modelEntity
                        appState.scene.addChild(modelEntity)

                    // 更新時
                    case .updated:
                        guard let modelEntity = meshEntities[meshAnchor.id] else { continue }
                        modelEntity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)

                    // 削除時
                    case .removed:
                        meshEntities[meshAnchor.id]?.removeFromParent()
                        meshEntities.removeValue(forKey: meshAnchor.id)
                    }
                }
            }

            // ----- 衝突判定の処理 ----- //

            // 衝突判定（開始時）
            _ = content.subscribe(to: CollisionEvents.Began.self) { collisionEvent in
                currentAppClass.handleCollisionBegin(entityA: collisionEvent.entityA, entityB: collisionEvent.entityB)
            }

            // 衝突判定（終了時）
            _ = content.subscribe(to: CollisionEvents.Ended.self) { collisionEvent in
                currentAppClass.handleCollisionEnded(entityA: collisionEvent.entityA, entityB: collisionEvent.entityB)
            }
        }
        attachments: {
            // アプリケーションを表示
            Attachment(id: "attachment1") {
                AnyView(currentAppView)
            }

            // アプリケーション選択画面を表示
            Attachment(id: "attachment2") {
                VStack {
                    VStack(spacing: 20) {
                        Text("アプリを選択")
                            .font(.system(size: 24, weight: .bold))
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(0..<metaBoxApps.count, id: \.self) { index in
                                Button {
                                    appState.selectionValue = index
                                } label: {
                                    HStack {
                                        Text(metaBoxApps[index].name)
                                        if appState.selectionValue == index {
                                            Image(systemName: "checkmark")
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .frame(width: 280)
                }
                .glassBackgroundEffect()
                .disabled(isTaskRunning)
            }
        }
        .onChange(of: appState.selectionValue) {
            // 全てのエンティティを削除
            currentAppClass.removeAllEntity(from: appState.scene)

            // アプリケーションを切り替え
            print("----- DEBUG!: Change to \(metaBoxApps[appState.selectionValue].name) -----")
            currentAppClass = metaBoxApps[appState.selectionValue].appClass
            currentAppView = metaBoxApps[appState.selectionValue].appView

            // デバッグモード切替
            currentAppClass.debugMode = appState.debugMode

            // 初期化
            currentAppClass.reset()

            // タスク開始時にフラグを上げる
            isTaskRunning = true

            Task {
                // タスク終了時にフラグを下ろす
                defer {
                    isTaskRunning = false
                }

                // オブジェクトアンカーに対してエンティティを追加
                for (_, anchorEntity) in objectAnchors {
                    await currentAppClass.addSkinEntity(anchorEntity: anchorEntity)
                    await currentAppClass.addEntityForObjectTracking(anchorEntity: anchorEntity)
                }

                // シーンに対してエンティティを追加
                await currentAppClass.addEntity(to: appState.scene)
            }
        }
        .onAppear() {
            // デバッグモード切替
            currentAppClass.debugMode = appState.debugMode

            Task {
                // 全モデルをプリロード
                await ModelLoader.shared.loadAllUSDModels()

                // オブジェクトアンカーに対してエンティティを追加
                for (_, anchorEntity) in objectAnchors {
                    await currentAppClass.addSkinEntity(anchorEntity: anchorEntity)
                    await currentAppClass.addEntityForObjectTracking(anchorEntity: anchorEntity)
                }

                // シーンに対してエンティティを追加
                await currentAppClass.addEntity(to: appState.scene)
            }

            // ハンドトラッキング関連の処理を実行
            timer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { _ in
                Task {
                    await currentAppClass.handTrackingInteraction(to: appState.scene)
                }
            }
        }
        .onDisappear() {
            // オブジェクトトラッキングを終了
            for (_, visualization) in objectAnchors {
                appState.scene.removeChild(visualization.entity)
            }
            objectAnchors.removeAll()

            // オブジェクトを削除
            currentAppClass.removeAllEntity(from: appState.scene)

            // ハンドジョイントを削除
            removeHandJointEntities(from: appState.scene)

            // タイマーを破棄
            timer?.invalidate()
            timer = nil

            // イマーシブスペースを終了
            appState.didLeaveImmersiveSpace()
        }
    }
}

extension GeometrySource {
    @MainActor func asArray<T>(ofType: T.Type) -> [T] {
        assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
        return (0..<self.count).map {
            buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
        }
    }

    // SIMD3 has the same storage as SIMD4.
    @MainActor  func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}
