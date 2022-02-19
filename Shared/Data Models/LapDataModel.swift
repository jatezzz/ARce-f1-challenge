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
    private var fastestLapPositions: [Motion] = []

    private var currentFrame = 0
    
    private var sceneEventsUpdateSubscription: Cancellable!
    private var carAnchor: AnchorEntity?
    
    private var cancellable = Set<AnyCancellable>()
        
    init () {
        // load the fastest lap
        //loadFastestLap()
        
        // Create the 3D view
        arView = ARView(frame: .zero)
        
        #if !targetEnvironment(simulator) && !os(macOS)
        arView.addCoaching()
        #endif
        
        // • The reference track, positioned in Reality Composer to match the API coordinated
        let carScene = try! COTA.loadTrack()
        arView.scene.anchors.append(carScene)
                        
        // Hidding the reference track
        let myTrack = carScene.track3!
        myTrack.isEnabled = false
        
        // • Loading the nice track from the usdc file
        let myTrackTransformed = try! Entity.load(named: "1960Final")
        
        let trackAnchor = AnchorEntity(world: .zero)
        trackAnchor.addChild(myTrackTransformed)
        
        myTrackTransformed.orientation = simd_quatf(angle: .pi/4, axis: [0,1,0])
                
        arView.scene.addAnchor(trackAnchor)
        
        // • The camera
        #if os(macOS)
        let cameraEntity = PerspectiveCamera()
        cameraEntity.camera.fieldOfViewInDegrees = 60
        let cameraAnchor = AnchorEntity(world: .zero)

        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)
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
        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            guard AppModel.shared.appState == .playing else { return }
                                    
            let cp = self.carPositions[self.currentFrame]
            self.currentSpeed = cp.mSpeed
            self.currentRPM = cp.mEngineRPM
            self.currentGear = cp.mGear
            self.currentSector = cp.mSector
            self.currentLap = cp.mCurrentLap
                        
            myCar.position = SIMD3<Float>([cp.mWorldposy, cp.mWorldposz, cp.mWorldposx]/1960)
            myCar.transform.rotation = Transform(pitch: cp.mPitch, yaw: cp.mYaw, roll: cp.mRoll).rotation
            
            // converting the API coordinates to match the visible track
            myCar.transform = myTrackTransformed.convert(transform: myCar.transform, to: myTrack)
            
            // showing the reference car
//            let rcp = self.fastestLapPositions[self.currentFrame]

//            fastestCar.position = SIMD3<Float>([rcp.mWorldposy, rcp.mWorldposz, rcp.mWorldposx]/1960)
//            fastestCar.transform.rotation = Transform(pitch: rcp.mPitch, yaw: rcp.mYaw, roll: rcp.mRoll).rotation
//
//            // converting the API coordinates to match the visible track
//            fastestCar.transform = myTrackTransformed.convert(transform: fastestCar.transform, to: myTrack)

            #if os(macOS)
            cameraEntity.look(at: myCar.position, from: [0.1, 0.1, 0], relativeTo: nil)
            boxEntity.position = [myCar.position.x, myCar.position.y + 0.05, myCar.position.z]
            trackingCone.position = [myCar.position.x, myCar.position.y + 0.05, myCar.position.z]
            #else
            trackingCone.position = [myCar.position.x, myCar.position.y + 0.05, myCar.position.z]
            #endif
            
//            let box = MeshResource.generateBox(size: 0.1) // Generate mesh
//            let entity = ModelEntity(mesh: box) // Create an entity from mesh
//
//            let anchor = AnchorEntity(world: [cp.mWorldposy/120, 0, cp.mWorldposx/120])
//            anchor.addChild(entity)
//
//            //self.arView.scene.addAnchor(anchor)
//            myTrack.addChild(anchor)
            
            self.currentFrame = (self.currentFrame < self.carPositions.count - 1) ? (self.currentFrame + 1) : 0
        }
    }
    
    private func loadFastestLap() {
        self.fastestLapPositions = []
        
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://apigw.withoracle.cloud/livelaps/carData/fastestlap")!)
            .map (\.data)
            .decode(type: LapData.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink { completion in
                print (completion)

                switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error) : AppModel.shared.appState = .error(msg: error.localizedDescription)
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
        self.currentFrame = 0
        
        fetchPositionData(for: session)
            .receive(on: RunLoop.main)
            .sink { completion in
                print (completion)
                
                switch completion {
                    case .finished: () // done, nothing to do
                    case let .failure(error) : AppModel.shared.appState = .error(msg: error.localizedDescription)
                }
            } receiveValue: { items in
                self.carPositions.append(contentsOf: items)
                
                if self.carPositions.count > 0 {
                    AppModel.shared.appState = .playing // we start playing after the first lap is loaded, the rest are coming in the background
                }
                
                print("*")
            }
            .store(in: &self.cancellable)
    }
    
    private func fetchPositionData(for session: Session) -> AnyPublisher<[Motion], Error>{
        (1...session.laps)
            .map { URL(string: "https://apigw.withoracle.cloud/formulaai/carData/\(session.mSessionid)/\($0)")! }
            .map { URLSession.shared.dataTaskPublisher(for: $0) }
            .publisher
            .flatMap(maxPublishers: .max(1)) { $0 } // we serialize the request because we want the laps in the correct order
            .map (\.data)
            .decode(type: LapData.self, decoder: JSONDecoder())
            //.map { $0.sorted { $0.mFrame < $1.mFrame } }
            .eraseToAnyPublisher()
    }
    // https://apigw.withoracle.cloud/formulaai/trackData/1127492326198450576/1
}
