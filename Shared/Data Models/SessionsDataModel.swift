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
        
        self.cancellable = NetworkHelper.shared.fetchCachedFile(for: "sessions_response", with: [Session].self)
                .receive(on: RunLoop.main)
                .sink { completion in
                    print(completion)

                    switch completion {
                    case .finished:
                        AppModel.shared.appState = .waitToLoadTrack
                    case let .failure(error):
                        AppModel.shared.appState = .error(msg: error.localizedDescription)
                    }
                
            } receiveValue: { items in
                self.sessions = items
                print("*")
            }
    }

    private func fetchSessionsData() -> AnyPublisher<[Session], Error> {
        let url = URL(string: "https://apigw.withoracle.cloud/formulaai/sessions")!

        return URLSession.shared
                .dataTaskPublisher(for: url)
                .map(\.data)
                .decode(type: SessionsData.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
    }

    private func fetchSessionsDataCache(for file: String) -> AnyPublisher<[Session], Error> {
        Deferred {
            Future<JSONDecoder.Input, Error> { promise in
                if let path = Bundle.main.path(forResource: file, ofType: "json") {
                    do {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                        promise(.success(data))
                    } catch {
                        promise(.failure(error))
                    }
                } else {
                    promise(.success(Data()))
                }
            }
        }
                .decode(type: [Session].self, decoder: JSONDecoder())
                //.map { $0.sorted { $0.mFrame < $1.mFrame } }
                .eraseToAnyPublisher()

    }

}
