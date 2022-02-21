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
import ARKit

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
        let myTrackTransformed = try! ModelEntity.load(named: "1960Final")


        myTrackTransformed.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])

//        installGestures(on: trackAnchor)

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

        // • Reference car
        let trackingCone2 = trackingCone.clone(recursive: true)
        let fastestCar = myCar.clone(recursive: true)
        fastestCar.addChild(trackingCone2)
        carScene.addChild(fastestCar)
        myCar.addChild(trackingCone)

        // Initially position the camera
        #if os(macOS)
        cameraEntity.look(at: myTrack.position, from: [0, 50, 0], relativeTo: nil)
        #endif

        // Run the car
        mainCar = ObjectInRace(entity: myCar, camera: cameraEntity, referenceEntityTransform: myTrackTransformed, referenceEntity: myTrack)

        secondCar = ObjectInRace(entity: fastestCar, camera: nil, referenceEntityTransform: myTrackTransformed, referenceEntity: myTrack)
        
        
        let container = createBox()
        placeBox(box: container, at: SIMD3(x: 0, y: 0, z: 0))
        container.addChild(myTrackTransformed)
        container.generateCollisionShapes(recursive: true)
        #if !os(macOS)
        arView.installGestures([.scale, .rotation], for: container)
        arView.debugOptions = [
//            .showPhysics,
//                                .showStatistics,
                                .showWorldOrigin,
                                .showAnchorOrigins,
                                .showAnchorGeometry,
                                .showFeaturePoints,
//                                .showSceneUnderstanding
        ]
        #endif
        
        let trackAnchor = AnchorEntity(world: .zero)
        trackAnchor.addChild(container)
        
        #if !targetEnvironment(simulator) && !os(macOS)
        arView.addCoaching()
        #endif
        arView.scene.anchors.append(carScene)
        arView.scene.addAnchor(trackAnchor)
        #if os(macOS)
        arView.scene.addAnchor(cameraAnchor)
        #endif
        
        
        let planeMesh = MeshResource.generatePlane(width: 0.15, depth: 0.15)
        let planeMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let planeEntity : ModelEntity? = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        let planeAnchor = AnchorEntity()
        planeAnchor.addChild(planeEntity!)
        arView.scene.addAnchor(planeAnchor)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnARView))
        arView.addGestureRecognizer(tapGesture)
        
        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.objects.indices.forEach({
                let viewData = self.objects[$0].update()
                if let viewData = viewData, $0 == 0 {
                    self.mainParticipant = viewData
                }
                if let viewData = viewData, $0 == 1 {
                    self.secondarticipant = viewData
                }
            })
            
            #if !os(macOS)
            guard let result = self.arView.raycast(from: self.arView.center, allowing: .estimatedPlane, alignment: .horizontal).first else {
            return

            }
            planeEntity!.setTransformMatrix(result.worldTransform, relativeTo: nil)
            #endif
            
        }
    }
    
    @objc func tapOnARView(sender: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        let location = sender.location(in: arView)
//        if let node = nodeAtLocation(location) {
//            removeCircle(node: node)
//        }
//        else
        if let result = raycastResult(fromLocation: location) {
            addCircle(raycastResult: result)
        }
    }
    
    private var circles: [Entity] = []
    private func raycastResult(fromLocation location: CGPoint) -> CollisionCastHit? {
        // let query = arView.makeRaycastQuery(from: location,
//    allowing: .existingPlaneGeometry,
//    alignment: .horizontal),
        guard let ray = self.arView.ray(through: location) else { return nil }
        
        let results = arView.scene.raycast(origin: ray.origin, direction: ray.direction)
//        let results = arView.session.raycast(query)
        print(results)
        return results.first
    }
    
    private func addCircle(raycastResult: CollisionCastHit) {
        let circleNode = GeometryUtils.createSphere()
        if circles.count >= 2 {
            for circle in circles {
                circle.removeFromParent()
            }
            circles.removeAll()
        }
        
        let planeAnchor = AnchorEntity(world: raycastResult.position)
        planeAnchor.addChild(circleNode)
        arView.scene.addAnchor(planeAnchor)
//        circleNode.setTransformMatrix(raycastResult.position, relativeTo: nil)
        
        circles.append(circleNode)
        nodesUpdated()
    }
    
    
    private func nodesUpdated() {
        if circles.count == 2 {
            let distance = GeometryUtils.calculateDistance(firstNode: circles[0], secondNode: circles[1])
            print("distance = \(distance)")
        }
    }

    func load(session: Session) {
        objects.removeAll()

//        let box2 = createBox()
//        placeBox(box: box2, at: SIMD3(x: 0, y: 0, z: 0))
//        installGestures(on: box2)

        loadSessionIntoModel(session: session, model: mainCar)
    }

    func createBox() -> ModelEntity{
        let box = MeshResource.generateBox(size: 0.08) // Generate mesh
        let boxMaterial = SimpleMaterial(color: .blue, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])
        return boxEntity
    }
    func placeBox(box:ModelEntity,at position: SIMD3<Float>){
        let boxAnchor = AnchorEntity(world: position)
        boxAnchor.addChild(box)
        arView.scene.addAnchor(boxAnchor)
    }
    
    func installGestures(on object: ModelEntity){
        object.generateCollisionShapes(recursive: true)
        #if !os(macOS)
        arView.installGestures([.rotation,.scale], for: object)
        #endif
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
