//
// Created by John Trujillo on 22/2/22.
//

import Foundation
import RealityKit

extension Entity {
    /// Billboards the entity to the targetPosition which should be provided in world space.
    func billboard(targetPosition: SIMD3<Float>) {
        look(at: targetPosition, from: position(relativeTo: nil), relativeTo: nil)
    }
}
