//
//  CalcClass.swift
//  metaBoxMR
//
//  Created by chiba yuto on 2024/12/12.
//

import ARKit
import RealityKit

class MathClass {
    // エンティティ間の距離計算
    func calcDistance(from entityA: Entity, to entityB: Entity) -> Float {
        // エンティティの位置を取得
        let positionA = entityA.position(relativeTo: nil)
        let positionB = entityB.position(relativeTo: nil)
        
        // 2点間の距離を計算
        return distance(positionA, positionB)
    }
        
    // エンティティ間の回転計算
    func calcRotation(from entityA: Entity, to entityB: Entity) -> simd_quatf {
        // エンティティの位置を取得
        let positionA = entityA.position(relativeTo: nil)
        let positionB = entityB.position(relativeTo: nil)
        
        // 方向ベクトルを計算
        let directionA = normalize(positionA)
        let directionB = normalize(positionB)
        
        // 回転角を計算
        let dotProduct = dot(directionA, directionB)
        let angle = acos(dotProduct)
        
        // 回転軸を計算
        let rotationAxis = normalize(cross(directionA, directionB))
        
        // 回転クォータニオンを生成
        if length(rotationAxis) == 0 {
            // 軸がゼロの場合、単位クォータニオンを返す
            return simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0))
        }
        return simd_quatf(angle: angle, axis: rotationAxis)
    }

    // クォータニオンからオイラー角を計算
    func quatToEulerAngles(_ quat: simd_quatf) -> SIMD3<Float>{
        var angles = SIMD3<Float>();
        let qfloat = quat.vector
        
        let test = qfloat.x*qfloat.y + qfloat.z*qfloat.w;
        
        if (test > 0.499) {
            
            angles.x = 2 * atan2(qfloat.x,qfloat.w)
            angles.y = (.pi / 2)
            angles.z = 0
            return  angles
        }
        if (test < -0.499) {
            angles.x = -2 * atan2(qfloat.x,qfloat.w)
            angles.y = -(.pi / 2)
            angles.z = 0
            return angles
        }
        
        let sqx = qfloat.x*qfloat.x;
        let sqy = qfloat.y*qfloat.y;
        let sqz = qfloat.z*qfloat.z;
        angles.x = atan2(2*qfloat.y*qfloat.w-2*qfloat.x*qfloat.z , 1 - 2*sqy - 2*sqz)
        angles.y = asin(2*test)
        angles.z = atan2(2*qfloat.x*qfloat.w-2*qfloat.y*qfloat.z , 1 - 2*sqx - 2*sqz)
        
        return angles
    }

}
