//
//  Extensions.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/12/06.
//

import ARKit
import RealityKit

extension ModelEntity {
    class func createFingertip() -> ModelEntity {
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
}
