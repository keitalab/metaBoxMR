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

    // ハンドトラッキング用
    private let fingerEntities: [HandAnchor.Chirality: ModelEntity] = [
        .left: .createFingertip(),
        .right: .createFingertip()
    ]

    var body: some View {
        RealityView { content, attachments in
            content.add(scene)  // シーンを追加

            Task {
                // ----- ハンドトラッキングの処理 ----- //
                
                // ハンドトラッキングを開始
                let handTracking = await appState.startHandTracking()
                guard let handTracking else {
                    return
                }
                
                // アンカー更新時に非同期で実行
                for await update in handTracking.anchorUpdates {
                    switch update.event {
                        // 更新時
                    case .updated:
                        // アンカーを更新
                        let anchor = update.anchor
                        
                        // ハンドトラッキングデータが有効かチェック
                        guard
                            anchor.isTracked,
                            let indexFingerTipJoint = anchor.handSkeleton?.joint(.indexFingerTip),
                            indexFingerTipJoint.isTracked else { continue }
                        
                        // 関節のグローバル座標を計算
                        // （アンカー座標からワールド座標の変換行列 * 関節座標からアンカー座標までの変換行列）
                        let originFromIndexFingerTip = anchor.originFromAnchorTransform * indexFingerTipJoint.anchorFromJointTransform
                        
                        // 関節エンティティの座標をグローバル座標に設定
                        fingerEntities[anchor.chirality]?.setTransformMatrix(originFromIndexFingerTip, relativeTo: nil)
                        
                        // 指先エンティティをシーンに追加
                        for (_, entity) in fingerEntities {
                            scene.addChild(entity)
                        }
                        
                        // その他
                    default:
                        break
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
                if collisionEvent.entityA.name == "handJoint" && collisionEvent.entityB.name == "metaBoxSkin" {
                    print("Collision Began!")
                    unlock()
                }
            }
            
            // 衝突判定（終了時）
            _ = content.subscribe(to: CollisionEvents.Ended.self) { collisionEvent in
                if collisionEvent.entityA.name == "handJoint" && collisionEvent.entityB.name == "metaBoxSkin" {
                    print("Collision Ended!")
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
