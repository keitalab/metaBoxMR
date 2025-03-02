//
//  TreasureBox.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/12/14.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent

final class TreasureBox: AppClass {
    static let shared = TreasureBox()

    var isGrabbing: Bool
    var isHit: Bool
    var isClose: Bool

    private let mathClass = MathClass()

    private var keyEntity: Entity?
    private var hitEntity: Entity?
    private var skinEntity: Entity?

    // 初期化
    override init() {
        self.isGrabbing = false
        self.isHit = false
        self.isClose = true
    }

    // リセット
    override func reset() {
        self.isGrabbing = false
        self.isHit = false
        self.isClose = true
    }

    // シーンにエンティティを追加
    override func addEntity(to scene: Entity) async {
        keyEntity = await createKeyEntity()
        scene.addChild(keyEntity!)
    }

    // スキンエンティティを追加
    override func addSkinEntity(anchorEntity: ObjectAnchorEntity) async {
        skinEntity = await createSkinEntity()
        anchorEntity.entity.addChild(skinEntity!)
    }

    // オブジェクトアンカーにエンティティを追加
    override func addEntityForObjectTracking(anchorEntity: ObjectAnchorEntity) async {
        hitEntity = createHitEntity()
        anchorEntity.entity.addChild(hitEntity!)
    }

    // エンティティを削除
    override func removeAllEntity(from scene: Entity) {
        // 保持している参照を使って直接削除
        self.keyEntity?.removeFromParent()
        self.hitEntity?.removeFromParent()
        self.skinEntity?.removeFromParent()

        // 参照をクリア
        self.keyEntity = nil
        self.hitEntity = nil
        self.skinEntity = nil
    }

    // 衝突開始
    override func handleCollisionBegin(entityA: Entity, entityB: Entity) {
        // キーエンティティと手
        if entityA.name.contains("HandJoint:Right_thumbTip") && entityB.name.contains("KeyEntity") {
            isGrabbing = true
        }

        // ヒットエンティティとキーエンティティ
        if entityA.name.contains("hitEntity_magicBox") && entityB.name.contains("KeyEntity") {
            print("DEBUG!: Collision Began between \(entityA.name) and \(entityB.name)")
            isHit = true
        }
    }

    // 衝突終了
    override func handleCollisionEnded(entityA: Entity, entityB: Entity) {
        // キーエンティティと手
        if entityA.name.contains("HandJoint:Right_thumbTip") && entityB.name.contains("KeyEntity") {
            isGrabbing = false
        }

        // ヒットエンティティとキーエンティティ
        if entityA.name.contains("hitEntity_magicBox") && entityB.name.contains("KeyEntity") {
            print("DEBUG!: Collision Ended between \(entityA.name) and \(entityB.name)")
            isHit = false
            isClose = true
        }
    }

    // ハンドトラッキング関係
    override func handTrackingInteraction(to scene: Entity) async {
        if let objectEntity1 = await scene.findEntity(named: "HandJoint:Right_thumbTip"),
           let objectEntity2 = await scene.findEntity(named: "HandJoint:Right_indexFingerIntermediateBase") {

            let distance = mathClass.calcDistance(from: objectEntity1, to: objectEntity2)
            let midpoint = mathClass.calcMidpoint(from: objectEntity1, to: objectEntity2)

            await grabKeyEntity(distance: distance, midpoint: midpoint, scene: scene)
            await openBox(scene: scene)
        }
    }



    // ----- ローカル関数 ----- //

    // キーエンティティを作成
    @MainActor
    private func createKeyEntity() async -> Entity {
        if let cachedModel = ModelLoader.shared.loadModels["Key"] {
            // 複製して新しいエンティティとして利用
            let keyEntity = cachedModel.clone(recursive: true)

            // 判定用に名前をつける
            keyEntity.name = "KeyEntity"

            // 位置を調整
            keyEntity.position = [0, 1.4, -0.4]

            // メッシュを取得
            let modelMesh = keyEntity.model!.mesh

            // CollisionComponentを作成
            let keyCollision = try? await CollisionComponent(
                shapes: [.generateConvex(from: modelMesh)],
                mode: .default
            )

            // PhysicsBodyComponentを作成
            var keyPhysicsBody = try? await PhysicsBodyComponent(
                shapes: [ShapeResource.generateConvex(from: modelMesh)],
                mass: 0.1,
                material: nil,
                mode: .dynamic
            )
            keyPhysicsBody?.isAffectedByGravity = false

            // Collision, PhysicsBodyを設定
            keyEntity.components.set(keyCollision!)
            keyEntity.components.set(keyPhysicsBody!)

            return keyEntity
        } else {
            return Entity()
        }
    }

    // ヒットエンティティを作成
    private func createHitEntity() -> Entity {
        // エンティティを作成
        let hitEntity = ModelEntity(
            mesh: .generateBox(size: [0.1, 0.1, 0.1]),
            materials: [SimpleMaterial(color: .green, isMetallic: false)]
        )

        // Materialを作成
        var material = UnlitMaterial(color: .red)

        if debugMode {
            material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.2))
        } else {
            material.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(floatLiteral: 0.0))
        }

        // 位置を調整
        hitEntity.position = [0.16, 0.18, 0]

        // 判定用に名前をつける
        hitEntity.name = "hitEntity_magicBox"

        // CollisionComponentを作成
        let hitCollision = CollisionComponent(
            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
            mode: .default
        )

        // Material, CollisionComponentを追加
        hitEntity.model?.materials = [material]
        hitEntity.components.set(hitCollision)

        return hitEntity
    }

    // スキンエンティティを作成
    @MainActor
    private func createSkinEntity() async -> Entity {
        // エンティティを作成
        if let cachedModel = ModelLoader.shared.loadModels["metaBoxSkin_TresureBox"] {
            // 複製して新しいエンティティとして利用
            let skinEntity = cachedModel.clone(recursive: true)

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
                mode: .kinematic
            )
            skinPhysicsBody?.isAffectedByGravity = false

            // Collision, PhysicsBodyを設定
            skinEntity.components.set(skinCollision!)
            skinEntity.components.set(skinPhysicsBody!)

            return skinEntity
        } else {
            return Entity()
        }
    }

    // キーを掴む処理
    private func grabKeyEntity(distance: Float, midpoint: simd_float3, scene: Entity) async {
        // 鍵を掴んでいるかつ距離が近い場合に鍵エンティティを操作
        if isGrabbing && distance < 0.1 {
            if let keyEntity = await scene.findEntity(named: "KeyEntity") {
                // 鍵エンティティの位置を中心点に設定
                await MainActor.run {
                    keyEntity.position = midpoint
                }

                if let wristEntity = await scene.findEntity(named: "HandJoint:Right_wrist") {
                    await MainActor.run {
                        // ワールド座標での手首の回転を取得
                        let wristGlobalRotation = wristEntity.orientation(relativeTo: nil)

                        // 鍵エンティティに手首の回転を適用
                        keyEntity.orientation = wristGlobalRotation

                        // 鍵エンティティに対してローカル回転を付与
                        let localXaxisRotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
                        keyEntity.orientation *= localXaxisRotation

                        let localZaxisRotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 0, 1))
                        keyEntity.orientation *= localZaxisRotation

                        let localYaxisRotation = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
                        keyEntity.orientation *= localYaxisRotation
                    }
                }
            }
        }
    }

    // 箱を開ける処理
    private func openBox(scene: Entity) async {
        if isHit && isGrabbing {
            if let wristEntity = await scene.findEntity(named: "HandJoint:Right_wrist"),
               let hitEntity = await scene.findEntity(named: "hitEntity_magicBox")
            {
                let wristRotation = await wristEntity.orientation(relativeTo: hitEntity)
                let wristEularAngle = mathClass.quaternionToEulerAngles(wristRotation)

                // PI/2以上の角度で鍵を開ける
                if wristEularAngle.x <= -(.pi/2) && isClose {
                    unlock()
                    isClose = false
                }
            }
        }
    }
}

struct TreasureBoxView: View {
    var body: some View {
        VStack {}
    }
}
