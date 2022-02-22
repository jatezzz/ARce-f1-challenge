//
// Created by John Trujillo on 20/2/22.
//

import Foundation
import Combine
import RealityKit
import UIKit

class ObjectInRace {

    var currentFrame = 0
    var frameQuantity = 0

    var name = ""
    var color: UIColor = .black

    var positionList: [Motion] = []
    let mainEntity: Entity
    let cameraEntity: PerspectiveCamera?
    let coneEntity: Entity
    let parentText = Entity()
    let brakeIndicator: ModelEntity
    let throttleIndicator: ModelEntity

    init(referenceModel: Entity, camera: PerspectiveCamera?, container: Entity, referenceCone: Entity, color: UIColor, name: String) {
        self.name = name
        self.color = color
        self.cameraEntity = camera

        mainEntity = referenceModel.clone(recursive: true)
        coneEntity = referenceCone.clone(recursive: true)

        mainEntity.addChild(coneEntity)
        container.addChild(mainEntity)
        mainEntity.setPosition(SIMD3.zero, relativeTo: nil)
        coneEntity.isEnabled = false
        mainEntity.isEnabled = false

        coneEntity.transform.scale = [1, 1, 1] * 200
        coneEntity.setPosition(SIMD3<Float>([0, 50, 0]), relativeTo: mainEntity)

        let externalLocator: ModelEntity = GeometryUtils.createSphere(color: color)
        mainEntity.addChild(externalLocator)
        externalLocator.transform.scale = [1, 1, 1] * 1000
        externalLocator.setPosition(SIMD3<Float>([0, 30, 0]), relativeTo: mainEntity)

        let internalLocator: ModelEntity = GeometryUtils.createSphere(color: color)
        mainEntity.addChild(internalLocator)
        internalLocator.transform.scale = [1, 1, 1] * 300
        internalLocator.setPosition(SIMD3<Float>([0, 3, 0]), relativeTo: mainEntity)


        let nameEntity: ModelEntity = GeometryUtils.createText(text: name)

        nameEntity.transform.scale = [1, 1, 1] * 50
        nameEntity.setPosition(SIMD3<Float>([0, 4, 0]), relativeTo: mainEntity)

        nameEntity.transform.rotation = Transform(pitch: 0.0, yaw: Float.pi, roll: 0.0).rotation
        parentText.setPosition(SIMD3<Float>([0, 4, 0]), relativeTo: mainEntity)

        parentText.addChild(nameEntity)
        mainEntity.addChild(parentText)


        brakeIndicator = GeometryUtils.createBox(color: .red)
        mainEntity.addChild(brakeIndicator)
        brakeIndicator.transform.scale = [1, 1, 1] * 10
        brakeIndicator.setPosition(SIMD3<Float>([10, 0, -4]), relativeTo: mainEntity)

        throttleIndicator = GeometryUtils.createBox(color: .yellow)
        mainEntity.addChild(throttleIndicator)
        throttleIndicator.transform.scale = [1, 1, 1] * 10
        throttleIndicator.setPosition(SIMD3<Float>([10, 0, 0]), relativeTo: mainEntity)
    }

    func reset() {
        positionList = []
        currentFrame = 0
    }

    func updateAndRetrieveViewData(view: ARView?) -> ParticipantViewData? {
        guard AppModel.shared.appState == .playing, !self.positionList.isEmpty, let view = view else { return nil }
        coneEntity.isEnabled = true
        mainEntity.isEnabled = true
        let cp = self.positionList[self.currentFrame]
        print(cp.brake)
        brakeIndicator.transform.scale = [1, cp.brake * 10 + 1, 1] * 10
        throttleIndicator.transform.scale = [1, cp.throttle * 10 + 1, 1] * 10
        mainEntity.position = SIMD3<Float>([cp.mWorldposy, cp.mWorldposz, cp.mWorldposx] / 1960)
        mainEntity.transform.rotation = Transform(pitch: cp.mPitch, yaw: cp.mYaw, roll: cp.mRoll).rotation
        parentText.billboard(targetPosition: view.cameraTransform.translation)
        // converting the API coordinates to match the visible track
        #if os(macOS)
        cameraEntity?.look(at: mainEntity.position, from: [0.1, 0.1, 0], relativeTo: nil)
        #endif
        self.currentFrame = (self.currentFrame < self.frameQuantity - 1) ? (self.currentFrame + 1) : 0
        return ParticipantViewData(currentSpeed: cp.mSpeed, currentRPM: cp.mEngineRPM, currentGear: cp.mGear, currentSector: cp.mSector, currentLap: cp.mCurrentLap, color: color, name: name)
    }
}

struct ParticipantViewData {
    var currentSpeed: Int = 0
    var currentRPM: Int = 0
    var currentGear: Int = 0
    var currentSector: Int = 0
    var currentLap: Int = 0
    var color: UIColor = .black
    var name: String = ""
}
