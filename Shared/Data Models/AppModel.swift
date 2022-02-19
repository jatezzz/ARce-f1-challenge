//
//  AppModel.swift
//  F1 mac app
//
//  Created by Bogdan Farca on 01.10.2021.
//

import Foundation

enum AppState: Equatable {
    case loadingSessions
    case loadingTrack
    case waitToLoadTrack
    case stopped
    case playing
    case error (msg: String)
}

final class AppModel: ObservableObject {
    static var shared = AppModel()
    
    @Published var appState = AppState.loadingSessions {
        didSet { print(" === \(appState) ===") }
    }
}
