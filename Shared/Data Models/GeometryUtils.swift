//
//  GeometryUtils.swift
//  SwiftUIARKit
//
//  Created by Gualtiero Frigerio on 20/05/21.
//

import Foundation

#if !os(macOS)
import ARKit
#endif
import RealityKit

class GeometryUtils {
    static func calculateDistance(first: SIMD3<Float>, second: SIMD3<Float>) -> Float {
        var distance: Float = sqrt(
                pow(second.x - first.x, 2) +
                        pow(second.y - first.y, 2) +
                        pow(second.z - first.z, 2)
        )

        distance *= 100 // convert in cm
        return abs(distance)
    }

    static func calculateDistance(firstNode: Entity, secondNode: Entity) -> Float {
        return calculateDistance(first: firstNode.position, second: secondNode.position)
    }

    #if !os(macOS)
    static func createCircle(fromRaycastResult result: ARRaycastResult) -> AnchorEntity {

        let circle = createSphere()
        let planeAnchor = AnchorEntity()
        planeAnchor.addChild(circle)

        return planeAnchor
    }

    static func createBox() -> ModelEntity {
        let box = MeshResource.generateBox(size: 0.08) // Generate mesh
        let boxMaterial = SimpleMaterial(color: .blue, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])
        return boxEntity
    }
    static  func createSphere() -> ModelEntity{
        let box = MeshResource.generateSphere(radius: 0.08) // Generate mesh
        let boxMaterial = SimpleMaterial(color: .blue, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])
        return boxEntity
    }

    static func placeBox(box: ModelEntity, at position: SIMD3<Float>) -> AnchorEntity {
        let boxAnchor = AnchorEntity(world: position)
        boxAnchor.addChild(box)
        return boxAnchor
    }

    #endif
}
