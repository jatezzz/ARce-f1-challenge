// *********************************************************************************************
// Copyright © 2021. Oracle and/or its affiliates. All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at
// http://oss.oracle.com/licenses/upl
// *********************************************************************************************

//  Filename: SessionsDataModel.swift


import Foundation
import Combine

final class NetworkHelper {
    static var shared = NetworkHelper()

    func fetchPositionData(for rawUrl: String) -> AnyPublisher<[Motion], Error> {
        URLSession.shared.dataTaskPublisher(for: URL(string: rawUrl)!)
                .map(\.data)
                .decode(type: LapData.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
    }

    func fetchCachedFile<T: Decodable>(for file: String, with: T.Type) -> AnyPublisher<T, Error> {
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
                .decode(type: T.self, decoder: JSONDecoder())
                //.map { $0.sorted { $0.mFrame < $1.mFrame } }
                .eraseToAnyPublisher()

    }

}
