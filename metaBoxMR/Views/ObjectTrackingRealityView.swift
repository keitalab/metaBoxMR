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
    var appState: AppState
    var scene = Entity()

    // オブジェクトトラッキング用
    @State private var objectAnchors: [UUID: ObjectAnchorEntity] = [:]
    
    // ハンドトラッキング用の指先エンティティを作成
    func createJointEntity() -> ModelEntity {
        // 関節部のエンティティを作成
        let jointEntity = ModelEntity(
            mesh: .generateSphere(radius: 0.01),
            materials: [SimpleMaterial(color: .green, isMetallic: false)]
        )

        // 判定用に名前をつける
        jointEntity.name = "handJoint"

        // Collisionを追加
        jointEntity.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: 0.01)],
                mode: .default
            )
        )

        return jointEntity
    }
    
    let handJoints: Array<AnchoringComponent.Target.HandLocation.HandJoint> = [
//        .forearmArm,
//        .forearmWrist,
//        .indexFingerIntermediateBase,
        .indexFingerTip,
//        .indexFingerKnuckle,
//        .indexFingerMetacarpal,
//        .indexFingerIntermediateTip,
//        .littleFingerIntermediateBase,
        .littleFingerTip,
//        .littleFingerKnuckle,
//        .littleFingerMetacarpal,
//        .littleFingerIntermediateTip,
//        .middleFingerIntermediateBase,
        .middleFingerTip,
//        .middleFingerKnuckle,
//        .middleFingerMetacarpal,
//        .middleFingerIntermediateTip,
//        .ringFingerIntermediateBase,
        .ringFingerTip,
//        .ringFingerKnuckle,
//        .ringFingerMetacarpal,
//        .ringFingerIntermediateTip,
//        .thumbIntermediateBase,
//        .thumbKnuckle,
//        .thumbIntermediateTip,
        .thumbTip,
//        .wrist
    ]
    
    func handJointName(for joint: AnchoringComponent.Target.HandLocation.HandJoint) -> String {
        switch joint {
        case .indexFingerTip: return "indexFingerTip"
        case .littleFingerTip: return "littleFingerTip"
        case .middleFingerTip: return "middleFingerTip"
        case .ringFingerTip: return "ringFingerTip"
        case .thumbTip: return "thumbTip"
        // 他のジョイントも必要に応じて追加
        default: return "unknownJoint"
        }
    }

    var body: some View {
        RealityView { content, attachments in
            content.add(scene)  // シーンを追加
                    
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

                        // スキンを配置
                        if let skinEntity = try? await ModelEntity(named: "metaBoxSkin1") {
                            // 判定用に名前をつける
                            skinEntity.name = "metaBoxSkin"
                            
                            // メッシュを取得
                            let modelMesh = skinEntity.model!.mesh
                            
                            // CollisionComponentを作成
                            let skinCollision = try? await CollisionComponent(
                                shapes: [.generateConvex(from: modelMesh)],
                                mode: .default
                            )

                            // PhysicsBodyComponentを作成
                            var skinPhysicsBody = try? await PhysicsBodyComponent(
                                shapes: [ShapeResource.generateConvex(from: modelMesh)],
                                mass: 0.1,
                                material: nil,
                                mode: .dynamic
                            )
                            skinPhysicsBody?.isAffectedByGravity = false

                            // Collision, PhysicsBodyを設定
                            skinEntity.components.set(skinCollision!)
                            skinEntity.components.set(skinPhysicsBody!)

                            // シーンに追加
                            anchorEntity.entity.addChild(skinEntity)
                        }
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
            
            // 衝突判定（開始時）
            _ = content.subscribe(to: CollisionEvents.Began.self) { collisionEvent in
                if collisionEvent.entityA.name.contains("HandJoint") && collisionEvent.entityB.name == "metaBoxSkin" {
                    print("Collision Began between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name)")
                }
            }
            
            // 衝突判定（終了時）
            _ = content.subscribe(to: CollisionEvents.Ended.self) { collisionEvent in
                if collisionEvent.entityA.name.contains("HandJoint") && collisionEvent.entityB.name == "metaBoxSkin" {
                    print("Collision Ended between \(collisionEvent.entityA.name) and \(collisionEvent.entityB.name)")
                }
            }
        }
        attachments: {
            Attachment(id: "attachmentId") {
                // アプリケーションを表示
                metaBoxApps[appState.selectionValue].action()
            }
        }
        .onAppear() {
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear() {
            for (_, visualization) in objectAnchors {
                scene.removeChild(visualization.entity)
            }
            objectAnchors.removeAll()
            appState.didLeaveImmersiveSpace()
        }
    }
}
