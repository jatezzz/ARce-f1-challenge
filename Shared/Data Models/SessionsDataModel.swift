// *********************************************************************************************
// Copyright © 2021. Oracle and/or its affiliates. All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at
// http://oss.oracle.com/licenses/upl
// *********************************************************************************************

//  Filename: SessionsDataModel.swift


import Foundation
import Combine

final class SessionsDataModel: ObservableObject {
    static var shared = SessionsDataModel()
    
    @Published var sessions: [Session] = []
    
    private var cancellable: AnyCancellable?
    
    init() {
        // Load the sessions data from ATP
        loadSessions()
    }
    
    func loadSessions() {
        self.sessions = []
        AppModel.shared.appState = .loadingSessions
        
        self.cancellable = fetchSessionsData()
            .receive(on: RunLoop.main)
            .sink { completion in
                print(completion)
                
                switch completion {
                    case .finished:
                        AppModel.shared.appState = .waitToLoadTrack
                    case let .failure(error) :
                        AppModel.shared.appState = .error(msg: error.localizedDescription)
                }
                
            } receiveValue: { items in
                self.sessions = items
                print("*")
            }
    }
    
    private func fetchSessionsData() -> AnyPublisher<[Session], Error>{
        let url = URL(string: "https://apigw.withoracle.cloud/formulaai/sessions")!
        
        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map (\.data)
            .decode(type: SessionsData.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
}
