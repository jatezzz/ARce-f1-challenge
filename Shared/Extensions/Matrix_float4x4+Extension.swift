//
// Created by John Trujillo on 22/2/22.
//

import Foundation
import ARKit

extension matrix_float4x4 {
    
    var translation: SCNVector3 {
        get {
            return SCNVector3Make(columns.3.x, columns.3.y, columns.3.z)
        }
    }
    var eulerAngles: SCNVector3 {
        get {
            // Get quaternions
            let qw = sqrt(1 + self.columns.0.x + self.columns.1.y + self.columns.2.z) / 2.0
            let qx = (self.columns.2.y - self.columns.1.z) / (qw * 4.0)
            let qy = (self.columns.0.z - self.columns.2.x) / (qw * 4.0)
            let qz = (self.columns.1.x - self.columns.0.y) / (qw * 4.0)
            let siny = +2.0 * (qw * qz + qx * qy)
            let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
            let yaw = atan2(siny, cosy)
            let sinp = +2.0 * (qw * qy - qz * qx)
            var pitch: Float
            if abs(sinp) >= 1 {
                pitch = copysign(Float.pi / 2, sinp)
            } else {
                pitch = asin(sinp)
            }
            let sinr = +2.0 * (qw * qx + qy * qz)
            let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
            let roll = atan2(sinr, cosr)
            return SCNVector3(yaw, pitch, roll)
        }
    }
}
