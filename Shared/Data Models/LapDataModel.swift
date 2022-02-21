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
#if !os(macOS)
import ARKit
#endif

final class LapDataModel: ObservableObject {

    static var shared = LapDataModel()

    @Published var arView: ARView!

    @Published var mainParticipant: ParticipantViewData = ParticipantViewData()
    @Published var secondarticipant: ParticipantViewData = ParticipantViewData()

    let mainCar: ObjectInRace
    let secondCar: ObjectInRace
    private var fastestLapPositions: [Motion] = []


    private var sceneEventsUpdateSubscription: Cancellable!
    private var carAnchor: AnchorEntity?

    private var cancellable = Set<AnyCancellable>()

    var objects: [ObjectInRace] = []

    init() {
        // Create the 3D view
        arView = ARView(frame: .zero)

        // • The reference track, positioned in Reality Composer to match the API coordinated
        let carScene = try! COTA.loadTrack()

        // Hidding the reference track
        let trackDefaultOnMap = carScene.track3!
        trackDefaultOnMap.isEnabled = false

        // • Loading the nice track from the usdc file
        let historicalTrack = try! Entity.load(named: "1960Final")

        historicalTrack.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])

        // • The camera
        let cameraEntity = PerspectiveCamera()
        #if os(macOS)
        cameraEntity.camera.fieldOfViewInDegrees = 60
        let cameraAnchor = AnchorEntity(world: .zero)

        cameraAnchor.addChild(cameraEntity)
        #endif

        // • The car
        let myCar = carScene.car!
        let trackingCone = carScene.trackingCone!

        myCar.transform.scale = [1, 1, 1] * 0.0008
        myCar.isEnabled = false
        trackingCone.isEnabled = false

        // Initially position the camera
        #if os(macOS)
        cameraEntity.look(at: trackDefaultOnMap.position, from: [0, 50, 0], relativeTo: nil)
        #endif

        // Run the car
        mainCar = ObjectInRace(referenceModel: myCar, camera: cameraEntity, container: historicalTrack, referenceCone: trackingCone)

        secondCar = ObjectInRace(referenceModel: myCar, camera: nil, container: historicalTrack, referenceCone: trackingCone)

        #if !os(macOS)

        let container = createBox(size: 0.001)
        placeBox(box: container, at: SIMD3.zero)
        container.addChild(historicalTrack)
        container.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: container).forEach {
            $0.addTarget(self, action: #selector(handleModelGesture))
        }
        arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins]
        #endif

        let trackAnchor = AnchorEntity(world: .zero)
        #if !os(macOS)
        trackAnchor.addChild(container)
        #else
        trackAnchor.addChild(historicalTrack)
        #endif

        #if !targetEnvironment(simulator) && !os(macOS)
        arView.addCoaching()
        #endif
        arView.scene.anchors.append(carScene)
        arView.scene.addAnchor(trackAnchor)
        #if os(macOS)
        arView.scene.addAnchor(cameraAnchor)
        #endif

        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.objects.indices.forEach({
                let viewData = self.objects[$0].updateAndRetrieveViewData()
                if let viewData = viewData, $0 == 0 {
                    self.mainParticipant = viewData
                }
                if let viewData = viewData, $0 == 1 {
                    self.secondarticipant = viewData
                }
            })
        }
    }

    #if !os(macOS)
    @objc func handleModelGesture(_ sender: Any) {
        switch sender {
        case let rotation as EntityRotationGestureRecognizer:
            print("Rotation and name:\(rotation.entity!.name)")
        case let translation as EntityTranslationGestureRecognizer:
            print("translation and nane \(translation.entity!.name)")
        case let scale as EntityScaleGestureRecognizer:
            print("In Scale")
        default:
            break
        }
    }
    #endif

    func load(session: Session) {
        objects.removeAll()
        loadSessionIntoModel(session: session, model: mainCar)
    }

    func createBox(size: Float = 0.08) -> ModelEntity {
        let box = MeshResource.generateBox(size: size) // Generate mesh
        let boxMaterial = SimpleMaterial(color: .blue, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])
        return boxEntity
    }

    func placeBox(box: ModelEntity, at position: SIMD3<Float>) {
        let boxAnchor = AnchorEntity(world: position)
        boxAnchor.addChild(box)
        arView.scene.addAnchor(boxAnchor)
    }

    func addSession(session: Session) {
        loadSessionIntoModel(session: session, model: secondCar)
    }

    private func loadSessionIntoModel(session: Session, model: ObjectInRace) {
        AppModel.shared.appState = .loadingTrack
        self.cancellable = []
        model.reset()

        NetworkHelper.shared.fetchPositionData(for: session)
                .receive(on: RunLoop.main)
                .sink { completion in
                    print(completion)
                    self.addModelToQueueAndSetupContainerProperties(model: model)

                    switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error): AppModel.shared.appState = .error(msg: error.localizedDescription)
                    }
                } receiveValue: { items in
                    model.positionList.append(contentsOf: items)

                    if model.positionList.count > 0 {
                        AppModel.shared.appState = .playing // we start playing after the first lap is loaded, the rest are coming in the background
                    }

                    print("*")
                }
                .store(in: &self.cancellable)
    }

    private func addModelToQueueAndSetupContainerProperties(model: ObjectInRace) {
        if objects.count >= 2 {
            objects.removeLast()
        }
        objects.append(model)
        let minQuantity = objects.map({ $0.positionList.count })
                .filter({ $0 > 0 })
                .min() ?? 0
        objects.forEach({ model in
            model.currentFrame = 0
            model.frameQuantity = minQuantity
        })
    }
}
