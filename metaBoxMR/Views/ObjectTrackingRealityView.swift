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
    var scene = Entity()
    var appState: AppState
    var appClass: AppClass
    var appView: AnyView
    
    @State private var timer: Timer?
    @State private var isGrabbing: Bool = false
    
    init(appState: AppState) {
        self.appState = appState
        self.appClass = metaBoxApps[appState.selectionValue].appClass
        self.appView = metaBoxApps[appState.selectionValue].appView
    }
    
    // ハンドトラッキング用の指先エンティティを作成
    func createJointEntity() -> ModelEntity {
        // 関節部のエンティティを作成
        let jointEntity = ModelEntity(
            mesh: .generateBox(size: [0.01, 0.01, 0.01]),
            materials: [SimpleMaterial(color: .green, isMetallic: false)]
        )
        
        // Materialを作成
        var material = UnlitMaterial(color: .red)
        material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.0))

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
    
    func removeHandJointEntities(from scene: Entity) {
        for child in scene.children {
            // "HandJoint"を含む名前のエンティティを削除
            if child.name.contains("HandJoint") {
                child.removeFromParent()
            } else {
                // 子エンティティも再帰的に探索
                removeHandJointEntities(from: child)
            }
        }
    }
    
    // オブジェクトトラッキング用のアンカーエンティティ
    @State private var objectAnchors: [UUID: ObjectAnchorEntity] = [:]
    
    // シーン検出用のアンカーエンティティ
    @State private var meshEntities = [UUID: ModelEntity]()
    
    func createCubeEntity() -> ModelEntity {
        // 立方体のエンティティを生成
        let cubeEntity = ModelEntity(
            mesh: .generateBox(size: [0.1, 0.1, 0.1]), // サイズを指定
            materials: [SimpleMaterial(color: .blue, isMetallic: false)]
        )
        
        // 衝突用コンポーネントを追加
        cubeEntity.components.set(
            CollisionComponent(
                shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
                mode: .default
            )
        )
        
        // 物理演算コンポーネントを追加
        cubeEntity.components.set(
            PhysicsBodyComponent(
                massProperties: .init(mass: 1.0), // 質量を指定
                material: .generate(friction: 0.5, restitution: 0.3), // 摩擦と反発係数
                mode: .dynamic // 動的物理演算を有効化
            )
        )
        
        cubeEntity.name = "Cube"
        
        return cubeEntity
    }

    var body: some View {
        RealityView { content, attachments in
            content.add(scene)  // シーンを追加

            Task {
                await appClass.addEntity(to: scene)
            }
            
            
            
            Task {
                // ----- ハンドトラッキングの処理 ----- //

                // ハンドトラッキングを開始
                let session = SpatialTrackingSession()
                let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
                
                if let unavailableCapabilities = await session.run(configuration) {
                    if unavailableCapabilities.anchor.contains(.hand) {
                        print("The device doesn't support plane tracking.")
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
                            scene.addChild(anchorEntity)
                        }
                    }
                }
            }

            Task {
                // ----- オブジェクトトラッキングの処理 ----- //

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
                        scene.addChild(anchorEntity.entity)

                        // 空のエンティティを配置（Attachment用）
                        if let attachmentEntity = attachments.entity(for: "attachmentId") {
                            attachmentEntity.position = [0.16, 0.18, 0]
                            attachmentEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: SIMD3<Float>(0,1,0))
                            anchorEntity.entity.addChild(attachmentEntity)
                        } else {
                            print("Attachment entity not found for ID: attachmentId")
                        }
                        
                        // オブジェクトトラッキング用にエンティティを追加
                        await appClass.addSkinEntity(anchorEntity: anchorEntity)
                        await appClass.addEntityForObjectTracking(anchorEntity: anchorEntity)
                        
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

                    guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
                    
                    // イベント
                    switch update.event {
                    // 追加時
                    case .added:
                        let anchorEntity = ModelEntity()
                        anchorEntity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
//                        anchorEntity.collision = CollisionComponent(shapes: [shape], isStatic: true)
//                        anchorEntity.components.set(InputTargetComponent())
//                        anchorEntity.physicsBody = PhysicsBodyComponent(mode: .static)
                        
                        meshEntities[meshAnchor.id] = anchorEntity
                        
                        scene.addChild(anchorEntity)
                        
                    // 更新時
                    case .updated:
                        guard let anchorEntity = meshEntities[meshAnchor.id] else { continue }
                        anchorEntity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
//                        anchorEntity.collision?.shapes = [shape]
                        
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
                appClass.handleCollisionBegin(entityA: collisionEvent.entityA, entityB: collisionEvent.entityB)
            }
            
            // 衝突判定（終了時）
            _ = content.subscribe(to: CollisionEvents.Ended.self) { collisionEvent in
                appClass.handleCollisionEnded(entityA: collisionEvent.entityA, entityB: collisionEvent.entityB)
            }
        }
        attachments: {
            Attachment(id: "attachmentId") {
                // アプリケーションを表示
                AnyView(appView)
            }
        }
        .onAppear() {
            appState.isImmersiveSpaceOpened = true

//            // 立方体を作成してシーンに追加
//            let cubeEntity = createCubeEntity()
//            cubeEntity.position = [0, 1, -0.5] // シーン内での配置位置を設定
//            scene.addChild(cubeEntity)

            // 処理の実行
            timer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { _ in
                Task {
                    await appClass.handTrackingInteraction(to: scene)
                }
            }
        }
        .onDisappear() {
            // オブジェクトトラッキングを終了
            for (_, visualization) in objectAnchors {
                scene.removeChild(visualization.entity)
            }
            objectAnchors.removeAll()
            
            // オブジェクトを削除
            appClass.removeEntity(from: scene)
            
            // ハンドジョイントを削除
            removeHandJointEntities(from: scene)
            
            // タイマーを破棄
            timer?.invalidate()
            timer = nil
            
            // イマーシブスペースを終了
            appState.didLeaveImmersiveSpace()
        }
    }
}
