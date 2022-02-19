//
//  ContentView.swift
//  F1 mac app
//
//  Created by Bogdan Farca on 01.09.2021.
//

import SwiftUI
import RealityKit

struct LapReplayView: View {
    @StateObject var dataModel = LapDataModel.shared
    @StateObject var appModel = AppModel.shared
    
    var session: Session
        
    var body: some View {
        ZStack {
            ARViewContainer()
                .ignoresSafeArea()
            
            if ![.playing, .stopped].contains(appModel.appState) {
                #if !os(macOS)
                    Color(UIColor.secondarySystemBackground).ignoresSafeArea()
                #else
                    Color.gray.ignoresSafeArea()
                #endif
            }
            
            switch appModel.appState {
                case .loadingTrack:
                    ProgressView("Loading session data from Oracle Cloud")

                case let .error(msg):
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                            .opacity(0.5)

                        Text("Error: \(msg)")
                    }

                case .playing, .stopped:
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            DataBubbleView()
                            renderStartStop()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                default: EmptyView()
            }
        }
        .onAppear {
            dataModel.load(session: session)
        }
    }
    
    @ViewBuilder
    private func renderStartStop() -> some View {
        HStack {
            Spacer()
            
            let playing = appModel.appState == .playing
            
            Button { appModel.appState = playing ? .stopped : .playing }
                label: { Image(systemName: playing ? "pause.circle" : "play.circle") }
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.white.opacity(0.3))
        .font(.system(size: 50))
        .padding()
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        if let s = SessionsDataModel.shared.sessions.first{
//            LapReplayView(session: s)
//        } else {
//            Text("Loading")
//        }
//    }
//}
