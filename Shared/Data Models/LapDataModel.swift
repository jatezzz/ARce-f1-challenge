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

    var subscriptions = Set<AnyCancellable>()

    @Published var arView: ARView!

    @Published var mainParticipant: ParticipantViewData = ParticipantViewData()
    @Published var secondarticipant: ParticipantViewData = ParticipantViewData()
    @Published var isInMeasureFunctionality = false

    let mainCar: ObjectInRace
    let secondCar: ObjectInRace
    private var fastestLapPositions: [Motion] = []
    
    let temporalParent = Entity()

    private var sceneEventsUpdateSubscription: Cancellable!
    private var carAnchor: AnchorEntity?

    private var cancellable = Set<AnyCancellable>()

    var objects: [ObjectInRace] = []
    var container : ModelEntity!
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

        container = createBox(size: 0.001)
        placeBox(box: container!, at: SIMD3.zero)
        container!.addChild(historicalTrack)
        container!.generateCollisionShapes(recursive: true)
        arView.installGestures([.scale, .rotation], for: container!).forEach {
            $0.addTarget(self, action: #selector(handleModelGesture))
        }
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnARView))
                arView.addGestureRecognizer(tapGesture)
        arView.debugOptions = [.showWorldOrigin, .showAnchorOrigins]
        #endif

        let trackAnchor = AnchorEntity(world: .zero)
        #if !os(macOS)
        trackAnchor.addChild(container!)
        trackAnchor.addChild(temporalParent)
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
        
//        var customCount = 0;

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
//            container.transform.rotation = simd_quatf(angle: (.pi / 400)*Float(customCount), axis: [1, 0, 0])
//            container.transform.translation = SIMD3<Float>([container.transform.translation.x, container.transform.translation.y+Float(customCount/1000), container.transform.translation.z])
//            customCount += 1
        }
    }
    
//    mainEntity.transform = referenceEntityTransform.convert(transform: mainEntity.transform, to: referenceEntity)

    var customBool = false
    var savedTransform : Transform?

    @objc func tapOnARView(sender: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        if isInMeasureFunctionality {
            let location = sender.location(in: arView)
            if let result = raycastResult(fromLocation: location) {
                addCircle(raycastResult: result)
            }
            return
        }
        if customBool, let savedTransform = savedTransform, let container = container {
            self.container?.transform.translation = container.transform.translation - (savedTransform.translation - arView.cameraTransform.translation)

        }
        savedTransform = arView.cameraTransform
        customBool = !customBool

    }


    private var circles: [Entity] = []

    private func raycastResult(fromLocation location: CGPoint) -> CollisionCastHit? {
        guard let ray = self.arView.ray(through: location) else { return nil }

        let results = arView.scene.raycast(origin: ray.origin, direction: ray.direction)
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

        container.addChild(circleNode)
        circleNode.setPosition(raycastResult.position, relativeTo: nil)
        circles.append(circleNode)
        nodesUpdated()
    }


    private func nodesUpdated() {
        if circles.count == 2 {
            let distance = GeometryUtils.calculateDistance(firstNode: circles[0], secondNode: circles[1])
            let textModel = GeometryUtils.createText(text: "\(distance)m")
            textModel.transform.scale = [1, 1, 1] * 0.05
            textModel.transform.rotation = Transform(pitch: 0.0, yaw: Float.pi, roll: 0.0).rotation
            textModel.setPosition(circles[1].position + [0, 0.01, 0], relativeTo: nil)
            let parentText = Entity()
            parentText.setPosition(circles[1].position + [0, 0.01, 0], relativeTo: nil)
            arView.scene.subscribe(to: SceneEvents.Update.self) { [self] _ in
                        parentText.billboard(targetPosition: arView.cameraTransform.translation)
                    }
                    .store(in: &subscriptions)

            parentText.addChild(textModel, preservingWorldTransform: true)
            container.addChild(parentText)
            circles.append(textModel)
            print("distance = \(distance)")
        }
    }

    func toogleMeasureFunctionality() {
        isInMeasureFunctionality = !isInMeasureFunctionality
        if !isInMeasureFunctionality, !circles.isEmpty {
            for circle in circles {
                circle.removeFromParent()
            }
            circles.removeAll()
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


extension matrix_float4x4 {
    // Function to convert rad to deg
    func radiansToDegress(radians: Float32) -> Float32 {
        return radians
    }
    var translation: SCNVector3 {
       get {
           return SCNVector3Make(columns.3.x, columns.3.y, columns.3.z)
       }
    }
    // Retrieve euler angles from a quaternion matrix
    var eulerAngles: SCNVector3 {
        get {
            // Get quaternions
            let qw = sqrt(1 + self.columns.0.x + self.columns.1.y + self.columns.2.z) / 2.0
            let qx = (self.columns.2.y - self.columns.1.z) / (qw * 4.0)
            let qy = (self.columns.0.z - self.columns.2.x) / (qw * 4.0)
            let qz = (self.columns.1.x - self.columns.0.y) / (qw * 4.0)

            // Deduce euler angles
            /// yaw (z-axis rotation)
            let siny = +2.0 * (qw * qz + qx * qy)
            let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
            let yaw = radiansToDegress(radians:atan2(siny, cosy))
            // pitch (y-axis rotation)
            let sinp = +2.0 * (qw * qy - qz * qx)
            var pitch: Float
            if abs(sinp) >= 1 {
                pitch = radiansToDegress(radians:copysign(Float.pi / 2, sinp))
            } else {
                pitch = radiansToDegress(radians: asin(sinp))
            }
            /// roll (x-axis rotation)
            let sinr = +2.0 * (qw * qx + qy * qz)
            let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
            let roll = radiansToDegress(radians: atan2(sinr, cosr))

            /// return array containing ypr values
            return SCNVector3(yaw, pitch, roll)
        }
    }
}

extension Entity {
    /// Billboards the entity to the targetPosition which should be provided in world space.
    func billboard(targetPosition: SIMD3<Float>) {
        look(at: targetPosition, from: position(relativeTo: nil), relativeTo: nil)
    }
}
