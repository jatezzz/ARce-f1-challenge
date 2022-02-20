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

    private var carPositions: [Motion] = []
    let customCar: ObjectInRace
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
        let box = MeshResource.generateBox(size: 0.03) // Generate mesh
        let boxMaterial = SimpleMaterial(color: .green, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])

        carScene.addChild(boxEntity)


        myCar.transform.scale = [1, 1, 1] * 0.0008

        // • Reference car
//        let fastestCar = myCar.clone(recursive: true)

        // Initially position the camera
        #if os(macOS)
        cameraEntity.look(at: myTrack.position, from: [0, 50, 0], relativeTo: nil)
        #endif

        // Run the car
        customCar = ObjectInRace(car: myCar, camera: cameraEntity, referenceEntityTransform: myTrackTransformed, referenceEntity: myTrack)


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
        self.carPositions = []
        customCar.trackPositions = []
        customCar.currentFrame = 0

        NetworkHelper.shared.fetchCachedFile(for: "track_response", with: [Track].self)
                .receive(on: RunLoop.main)
                .sink { completion in
                    print(completion)

                    switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error): AppModel.shared.appState = .error(msg: error.localizedDescription)
                    }
                } receiveValue: { items in
                    self.customCar.trackPositions.append(contentsOf: items)

                    if self.customCar.trackPositions.count > 0 {
                        AppModel.shared.appState = .playing // we start playing after the first lap is loaded, the rest are coming in the background
                    }

                    print("*")
                }
                .store(in: &self.cancellable)
    }

    private func fetchPositionData(for session: Session) -> AnyPublisher<[Motion], Error> {
//        (1...session.laps)
//            .map { URL(string: "https://apigw.withoracle.cloud/formulaai/carData/1127492326198450576/1/0")! }
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://apigw.withoracle.cloud/formulaai/carData/1127492326198450576/1/0")!)
                //            .flatMap(maxPublishers: .max(1)) { $0 } // we serialize the request because we want the laps in the correct order
                .map(\.data)
                .decode(type: LapData.self, decoder: JSONDecoder())
                //.map { $0.sorted { $0.mFrame < $1.mFrame } }
                .eraseToAnyPublisher()
    }

    private func fetchTrackData(for session: Session) -> AnyPublisher<[Track], Error> {
//        (1...session.laps)
//            .map { URL(string: "https://apigw.withoracle.cloud/formulaai/carData/1127492326198450576/1/0")! }
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://apigw.withoracle.cloud/formulaai/v2/trackData/13315121676340788867/1")!)
                //            .flatMap(maxPublishers: .max(1)) { $0 } // we serialize the request because we want the laps in the correct order
                //                .map(\.data)
                .map({
                    let stringRepresentation = String(data: $0.data, encoding: .utf8)
                    print(stringRepresentation!)
                    return $0.data
                })
                .decode(type: [Track].self, decoder: JSONDecoder())
                //.map { $0.sorted { $0.mFrame < $1.mFrame } }
                .eraseToAnyPublisher()
    }


    // https://apigw.withoracle.cloud/formulaai/trackData/1127492326198450576/1
}


class ObjectInRace {

    var currentFrame = 0

    var trackPositions: [Track] = []
    let myCar: Entity
    let cameraEntity: PerspectiveCamera
    let referenceEntity: Entity
    let referenceEntityTransform: Entity

    init(car: Entity, camera: PerspectiveCamera, referenceEntityTransform: Entity, referenceEntity: Entity) {
        myCar = car
        self.cameraEntity = camera
        self.referenceEntityTransform = referenceEntityTransform
        self.referenceEntity = referenceEntity
    }

    func update() {
        guard AppModel.shared.appState == .playing else { return }

        let cp = self.trackPositions[self.currentFrame]

        myCar.position = SIMD3<Float>([cp.mWorldposy, cp.mWorldposz, cp.mWorldposx] / 1960)
        myCar.transform.rotation = Transform(pitch: Float.pi, yaw: 0, roll: 0).rotation

        // converting the API coordinates to match the visible track
        myCar.transform = referenceEntityTransform.convert(transform: myCar.transform, to: referenceEntity)

        #if os(macOS)
        cameraEntity.look(at: myCar.position, from: [0.1, 0.1, 0], relativeTo: nil)
        #endif
        self.currentFrame = (self.currentFrame < self.trackPositions.count - 1) ? (self.currentFrame + 1) : 0
    }
}
