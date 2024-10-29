/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view shown inside the immersive space.
*/

import RealityKit
import ARKit
import SwiftUI

@MainActor
struct ObjectTrackingRealityView: View {
    var appState: AppState
    var root = Entity()
    
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    
    @State var entityIds: [UUID] = []
    
    var body: some View {
        RealityView { content, attachments in
            content.add(root)
            
            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    
//                    if !entityIds.contains(id) {
//                        entityIds.append(id)
//                    }
                    
                    switch anchorUpdate.event {
                    case .added:
                        let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let visualization = ObjectAnchorVisualization(for: anchor, withModel: model)
                        self.objectVisualizations[id] = visualization
                        root.addChild(visualization.entity)
                        
                        if let entityId = attachments.entity(for: "testId") {
                            entityId.position = [0.16, 0.18, 0]
                            entityId.transform.rotation = simd_quatf(angle: Float.pi/2, axis: SIMD3<Float>(0,1,0))
                            visualization.entity.addChild(entityId)
                        }
                        
//                        // 複数エンティティの場合
//                        if let entityId = attachments.entity(for: id) {
//                            entityId.position = [0, 0.2, 0]
//                            visualization.entity.addChild(entityId)
//                        }
//                        // デバッグ用
//                        let _ = print("UUIDs : \(entityIds)")
//                        let _ = print("Current UUID : \(id)")
                        
                    case .updated:
                        self.objectVisualizations[id]?.update(with: anchor)
                    case .removed:

//                        entityIds.removeAll { $0 == id }
                        
                        self.objectVisualizations[id]?.entity.removeFromParent()
                        self.objectVisualizations.removeValue(forKey: id)
                    }
                }
            }
        } attachments: {
            Attachment(id: "testId") {
                metaBoxApps[appState.selectionValue].action()
            }
            
//                // 複数エンティティの場合
//                ForEach(entityIds, id: \.self) { key in
//                Attachment(id: key) {
//                Text("Windows")
//                .font(.largeTitle)
//                .padding()
//                .background(Color.white.opacity(0.7))
//
//                // デバッグ用
//                let _ = print("Attachment Key : \(key)")
//                }
//                }
        }
        .onAppear() {
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear() {
            for (_, visualization) in objectVisualizations {
                root.removeChild(visualization.entity)
            }
            objectVisualizations.removeAll()
            appState.didLeaveImmersiveSpace()
        }
    }
}
