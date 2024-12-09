import ARKit
import RealityKit
import SwiftUI

@MainActor
class ObjectAnchorEntity {
    var entity: Entity
    
    // ObjectAnchorEntityの初期化
    init(for anchor: ObjectAnchor, withModel model: Entity? = nil) {
        let entity = Entity()
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked
        
        self.entity = entity
    }
    
    // ObjectAnchorEntityの更新
    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked
        guard anchor.isTracked else { return }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
    }
}
