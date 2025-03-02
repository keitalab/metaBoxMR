//
//  AppClass.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/12/14.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

class AppClass: ObservableObject {
    var debugMode: Bool = false

    private var skinEntity: Entity?

    // 初期化
    func reset() {
    }

    // シーンにエンティティを追加
    @MainActor
    func addEntity(to scene: Entity) async {
    }

    // スキンを追加
    @MainActor
    func addSkinEntity(anchorEntity: ObjectAnchorEntity) async {
        skinEntity = await createSkinEntity()
        anchorEntity.entity.addChild(skinEntity!)
    }

    // オブジェクトアンカーにエンティティを追加
    @MainActor
    func addEntityForObjectTracking(anchorEntity: ObjectAnchorEntity) async {
    }

    // エンティティを削除
    @MainActor
    func removeAllEntity(from scene: Entity) {
        self.skinEntity?.removeFromParent()
        self.skinEntity = nil
    }

    // 衝突開始
    func handleCollisionBegin(entityA: Entity, entityB: Entity) {
    }

    // 衝突終了
    func handleCollisionEnded(entityA: Entity, entityB: Entity) {
    }

    // ハンドトラッキング関係
    func handTrackingInteraction(to scene: Entity) async {
    }

    // スキンエンティティを作成（プライベート）
    @MainActor
    private func createSkinEntity() async -> Entity {
        // エンティティを作成
        if let cachedModel = ModelLoader.shared.loadModels["metaBoxSkin_Transparent"] {
            // 複製して新しいエンティティとして利用
            let skinEntity = cachedModel.clone(recursive: true)

            // 判定用に名前をつける
            skinEntity.name = "metaBoxSkin"

            // メッシュを取得
            let modelMesh = skinEntity.model!.mesh

            // Materialを作成
            var material = UnlitMaterial(color: .red)

            if debugMode {
                material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.2))
            } else {
                material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.0))
            }

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

            // Material, Collision, PhysicsBodyを設定
            skinEntity.model?.materials = [material]
            skinEntity.components.set(skinCollision!)
            skinEntity.components.set(skinPhysicsBody!)

            return skinEntity
        } else {
            return Entity()
        }
    }

    // SwiftUIのViewを返す
    struct AppView: View {
        var body: some View {
            Text("Hello, World!")
        }
    }
}
