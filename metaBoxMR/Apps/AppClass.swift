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
    // シーンにエンティティを追加
    @MainActor
    func addEntity(to scene: Entity) async {
    }
    
    @MainActor
    func addSkinEntity(anchorEntity: ObjectAnchorEntity) async {
        // エンティティを作成
        if let skinEntity = try? await ModelEntity(named: "metaBoxSkin_Transparent") {
            // 判定用に名前をつける
            skinEntity.name = "metaBoxSkin"
            
            // メッシュを取得
            let modelMesh = skinEntity.model!.mesh
            
            // Materialを作成
            var material = UnlitMaterial(color: .red)
            material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.0))
            
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
            
            // スケールを1.05倍に設定
            let currentTransform = skinEntity.transform
            skinEntity.transform = Transform(
                scale: currentTransform.scale * 1.05,
                rotation: currentTransform.rotation,
                translation: currentTransform.translation
            )
            
            // スキンエンティティをアンカーエンティティに追加
            anchorEntity.entity.addChild(skinEntity)
        }
    }
    
    // オブジェクトアンカーにエンティティを追加
    @MainActor
    func addEntityForObjectTracking(anchorEntity: ObjectAnchorEntity) async {
    }
    
    // エンティティを削除
    @MainActor
    func removeEntity(from scene: Entity) {
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
    
    // エンティティを削除
    func removeEntityFromScene(named entityName: String, from scene: Entity) {
        if let entity = scene.findEntity(named: entityName) {
            entity.removeFromParent()
        }
    }
    
    // SwiftUIのViewを返す
    struct AppView: View {
        var body: some View {
            Text("Hello, World!")
        }
    }
}
