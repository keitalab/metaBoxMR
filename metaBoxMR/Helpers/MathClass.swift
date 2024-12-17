//
//  MathClass.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/12/12.
//

import ARKit
import RealityKit

class MathClass {
    // エンティティ間の距離を計算
    func calcDistance(from entityA: Entity, to entityB: Entity) -> Float {
        // エンティティの位置を取得
        let positionA = entityA.position(relativeTo: nil)
        let positionB = entityB.position(relativeTo: nil)
        
        // 2点間の距離を計算
        return distance(positionA, positionB)
    }
    
    // エンティティ間の中心点を計算
    func calcMidpoint(from entityA: Entity, to entityB: Entity) -> simd_float3 {
        // エンティティの位置を取得
        let positionA = entityA.position(relativeTo: nil)
        let positionB = entityB.position(relativeTo: nil)
        
        // 中心点を計算
        return (positionA + positionB) / 2
    }
        
    // エンティティ間の回転を計算
    func calcRotation(from entityA: Entity, to entityB: Entity) -> simd_quatf {
        // 基準ベクトル、基準の回転軸を設定
        let referenceDirection = SIMD3<Float>(0, 0, -1)
        let referenceRotationAxis = SIMD3<Float>(0, 0, -1)
        
        // AおよびBのワールド座標系における位置を取得
        let positionA = entityA.convert(position: entityA.position, to: nil)
        let positionB = entityB.convert(position: entityB.position, to: nil)
        
        // 指向ベクトルを計算
        let directionVector = positionB - positionA
        
        // ベクトルの正規化
        let normalizedDirection = normalize(directionVector)
        let normalizedReferenceDirection = normalize(referenceDirection)
        
        // 内積の計算
        let dotProduct = dot(normalizedDirection, normalizedReferenceDirection)
        
        // 外積の計算
        let rotationAxis = cross(normalizedDirection, normalizedReferenceDirection)
            
        // 回転方向の判定
        var rotationDirection = "Unknown"
        if length(rotationAxis) > 1e-6 {
            let normalizedRotationAxis = normalize(rotationAxis)
            let directionDeterminant = dot(normalizedRotationAxis, referenceRotationAxis)
            
            if directionDeterminant > 0 {
                rotationDirection = "CCW"
            } else if directionDeterminant < 0 {
                rotationDirection = "CW"
            }
        }
        
        // 回転角の計算
        let rotationAngle = acos(dotProduct)
        
        // 回転方向に応じて回転角の符号を調整
        var adjustedRotationAngle = rotationAngle
        if rotationDirection == "CW" {
            adjustedRotationAngle = -rotationAngle
        }
        
        return simd_quatf(angle: adjustedRotationAngle, axis: normalize(rotationAxis))
    }

    // クォータニオンからオイラー角を計算
    func quaternionToEulerAngles(_ q: simd_quatf) -> SIMD3<Float> {
        // クォータニオンの各成分を取得
        let w = q.vector.w
        let x = q.vector.x
        let y = q.vector.y
        let z = q.vector.z
        
        // Roll (X軸回り)
        let sinr_cosp = 2.0 * (w * x + y * z)
        let cosr_cosp = 1.0 - 2.0 * (x * x + y * y)
        let roll = atan2(sinr_cosp, cosr_cosp)
        
        // Pitch (Y軸回り)
        // 値が -1 を下回る、または 1 を上回る場合はクランプする（浮動小数演算誤差対策）
        let sinp = 2.0 * (w * y - z * x)
        let pitch: Float
        if abs(sinp) >= 1.0 {
            // ピッチが ±90°を越えた場合には、asinで計算できる範囲を超えるためクランプする
            pitch = Float.pi / 2.0 * (sinp > 0.0 ? 1.0 : -1.0)
        } else {
            pitch = asin(sinp)
        }
        
        // Yaw (Z軸回り)
        let siny_cosp = 2.0 * (w * z + x * y)
        let cosy_cosp = 1.0 - 2.0 * (y * y + z * z)
        let yaw = atan2(siny_cosp, cosy_cosp)
        
        return SIMD3<Float>(roll, pitch, yaw)
    }
}
