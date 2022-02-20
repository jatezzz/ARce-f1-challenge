//
// Created by John Trujillo on 20/2/22.
//

import Foundation
import Combine
import RealityKit

class ObjectInRace {

    var currentFrame = 0
    var frameQuantity = 0

    var positionList: [Motion] = []
    let mainEntity: Entity
    let cameraEntity: PerspectiveCamera?
    let referenceEntity: Entity
    let referenceEntityTransform: Entity
    let coneEntity: Entity?

    init(entity: Entity, camera: PerspectiveCamera?, referenceEntityTransform: Entity, referenceEntity: Entity) {
        mainEntity = entity
        coneEntity = mainEntity.children.first(where: {
            $0.name == "Tracking Cone"
        })
        coneEntity?.transform.scale = [1, 1, 1] * 200
        coneEntity?.setPosition(SIMD3<Float>([0, 50, 0]), relativeTo: mainEntity)

        self.cameraEntity = camera
        self.referenceEntityTransform = referenceEntityTransform
        self.referenceEntity = referenceEntity
    }

    func reset() {
        positionList = []
        currentFrame = 0
    }

    func update() -> ParticipantViewData? {
        guard AppModel.shared.appState == .playing, !self.positionList.isEmpty, let coneEntity = coneEntity else { return nil }

        let cp = self.positionList[self.currentFrame]
        mainEntity.position = SIMD3<Float>([cp.mWorldposy, cp.mWorldposz, cp.mWorldposx] / 1960)
        mainEntity.transform.rotation = Transform(pitch: cp.mPitch, yaw: cp.mYaw, roll: cp.mRoll).rotation

        // converting the API coordinates to match the visible track
        mainEntity.transform = referenceEntityTransform.convert(transform: mainEntity.transform, to: referenceEntity)

        #if os(macOS)
        cameraEntity?.look(at: mainEntity.position, from: [0.1, 0.1, 0], relativeTo: nil)
        #endif
        self.currentFrame = (self.currentFrame < self.frameQuantity - 1) ? (self.currentFrame + 1) : 0
        return ParticipantViewData(currentSpeed: cp.mSpeed, currentRPM: cp.mEngineRPM, currentGear: cp.mGear, currentSector: cp.mSector, currentLap: cp.mCurrentLap)
    }
}

struct ParticipantViewData {
    var currentSpeed: Int = 0
    var currentRPM: Int = 0
    var currentGear: Int = 0
    var currentSector: Int = 0
    var currentLap: Int = 0
}
