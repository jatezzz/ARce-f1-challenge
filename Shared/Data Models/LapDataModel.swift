//
//  DataModel.swift
//  DataModel
//
//  Created by Bogdan Farca on 26.08.2021.
//

import Foundation
import Combine
import RealityKit
import SwiftUI

final class LapDataModel: ObservableObject {

    static var shared = LapDataModel()

    @Published var arView: ARView!

    @Published var currentSpeed: Int = 0
    @Published var currentRPM: Int = 0
    @Published var currentGear: Int = 0
    @Published var currentSector: Int = 0
    @Published var currentLap: Int = 0

    let customCar: ObjectInRace
    let boxObjectInModel: ObjectInRace
    private var fastestLapPositions: [Motion] = []


    private var sceneEventsUpdateSubscription: Cancellable!
    private var carAnchor: AnchorEntity?

    private var cancellable = Set<AnyCancellable>()

    init() {
        // load the fastest lap
        //loadFastestLap()

        // Create the 3D view
        arView = ARView(frame: .zero)


        // • The reference track, positioned in Reality Composer to match the API coordinated
        let carScene = try! COTA.loadTrack()

        // Hidding the reference track
        let myTrack = carScene.track3!
        myTrack.isEnabled = false

        // • Loading the nice track from the usdc file
        let myTrackTransformed = try! Entity.load(named: "1960Final")

        let trackAnchor = AnchorEntity(world: .zero)
        trackAnchor.addChild(myTrackTransformed)

        myTrackTransformed.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])


        // • The camera
        #if os(macOS)
        let cameraEntity = PerspectiveCamera()
        cameraEntity.camera.fieldOfViewInDegrees = 60
        let cameraAnchor = AnchorEntity(world: .zero)

        cameraAnchor.addChild(cameraEntity)
        #endif


        // • The car
        let myCar = carScene.car!
        let trackingCone = carScene.trackingCone!


        //Box
        let box = MeshResource.generateBox(size: 0.005) // Generate mesh
        let boxMaterial = SimpleMaterial(color: .green, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])

        carScene.addChild(boxEntity)


        myCar.transform.scale = [1, 1, 1] * 0.0008

        // • Reference car
        let fastestCar = myCar.clone(recursive: true)

        // Initially position the camera
        #if os(macOS)
        cameraEntity.look(at: myTrack.position, from: [0, 50, 0], relativeTo: nil)
        #endif

        // Run the car
        customCar = ObjectInRace(entity: myCar, camera: cameraEntity, referenceEntityTransform: myTrackTransformed, referenceEntity: myTrack)
        boxObjectInModel = ObjectInRace(entity: boxEntity, camera: nil, referenceEntityTransform: myTrackTransformed, referenceEntity: myTrack)

        #if !targetEnvironment(simulator) && !os(macOS)
        arView.addCoaching()
        #endif
        arView.scene.anchors.append(carScene)
        arView.scene.addAnchor(trackAnchor)
        #if os(macOS)
        arView.scene.addAnchor(cameraAnchor)
        #endif
        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            self.customCar.update()
            self.boxObjectInModel.update()
        }
    }

    private func loadFastestLap() {
        self.fastestLapPositions = []

        URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://apigw.withoracle.cloud/livelaps/carData/fastestlap")!)
                .map(\.data)
                .decode(type: LapData.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink { completion in
                    print(completion)

                    switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error): AppModel.shared.appState = .error(msg: error.localizedDescription)
                    }
                } receiveValue: { items in
                    self.fastestLapPositions.append(contentsOf: items)
                    print("*-")
                }
                .store(in: &self.cancellable)
    }

    func load(session: Session) {
        AppModel.shared.appState = .loadingTrack
        self.cancellable = []
        customCar.reset()
        NetworkHelper.shared.fetchPositionData(for: session)
                .receive(on: RunLoop.main)
                .sink { completion in
                    print(completion)
                    self.customCar.frameQuantity = self.customCar.positionList.count

                    switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error): AppModel.shared.appState = .error(msg: error.localizedDescription)
                    }
                } receiveValue: { items in
                    self.customCar.positionList.append(contentsOf: items)

                    if self.customCar.positionList.count > 0 {
                        AppModel.shared.appState = .playing // we start playing after the first lap is loaded, the rest are coming in the background
                    }

                    print("*")
                }
                .store(in: &self.cancellable)
    }

    func addSession(session: Session) {
        AppModel.shared.appState = .loadingTrack
        self.cancellable = []
        boxObjectInModel.reset()
        NetworkHelper.shared.fetchPositionData(for: session)
                .receive(on: RunLoop.main)
                .sink { completion in
                    print(completion)
                    let heights = [self.boxObjectInModel.positionList.count, self.customCar.positionList.count]
                    self.boxObjectInModel.frameQuantity = heights.min() ?? self.boxObjectInModel.positionList.count
                    self.customCar.frameQuantity = heights.min() ?? self.customCar.positionList.count

                    switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error): AppModel.shared.appState = .error(msg: error.localizedDescription)
                    }
                } receiveValue: { items in
                    self.boxObjectInModel.positionList.append(contentsOf: items)

                    if self.boxObjectInModel.positionList.count > 0 {
                        AppModel.shared.appState = .playing // we start playing after the first lap is loaded, the rest are coming in the background
                    }

                    print("*")
                }
                .store(in: &self.cancellable)
    }
}


class ObjectInRace {

    var currentFrame = 0
    var frameQuantity = 0

    var positionList: [LocationInModel] = []
    let mainEntity: Entity
    let cameraEntity: PerspectiveCamera?
    let referenceEntity: Entity
    let referenceEntityTransform: Entity

    init(entity: Entity, camera: PerspectiveCamera?, referenceEntityTransform: Entity, referenceEntity: Entity) {
        mainEntity = entity
        self.cameraEntity = camera
        self.referenceEntityTransform = referenceEntityTransform
        self.referenceEntity = referenceEntity
    }

    func reset() {
        positionList = []
        currentFrame = 0
    }

    func update() {
        guard AppModel.shared.appState == .playing, !self.positionList.isEmpty else { return }

        let cp = self.positionList[self.currentFrame]

        mainEntity.position = SIMD3<Float>([cp.mWorldposy, cp.mWorldposz, cp.mWorldposx] / 1960)
        mainEntity.transform.rotation = Transform(pitch: Float.pi, yaw: 0, roll: 0).rotation

        // converting the API coordinates to match the visible track
        mainEntity.transform = referenceEntityTransform.convert(transform: mainEntity.transform, to: referenceEntity)

        #if os(macOS)
        cameraEntity?.look(at: mainEntity.position, from: [0.1, 0.1, 0], relativeTo: nil)
        #endif
        self.currentFrame = (self.currentFrame < self.frameQuantity - 1) ? (self.currentFrame + 1) : 0
    }
}
