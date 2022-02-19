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
    @StateObject var sessionsModel = SessionsDataModel.shared

    @State var selectionIndex: String = ""
    
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
                    ZStack {
                        HStack(alignment: .bottom) {
                            DataBubbleView()
                                .frame(alignment: .leading)
                            Spacer()
                            if !selectionIndex.isEmpty {
                                DataBubbleView()
                                    .frame(alignment: .trailing)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            default: EmptyView()
            }
        }
        .onAppear {
            dataModel.load(session: session)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort by", selection: $selectionIndex) {
                        ForEach(sessionsModel.sessions.filter { $0.trackId == session.trackId }, id: \.mSessionid) { session in
                            Text("\(session.driver) - \(session.mSessionid)").tag(session.mSessionid)
                        }
                        Text("Deselect").tag("")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                let playing = appModel.appState == .playing

                Button(action: {

                }, label: {
                    Image(systemName: "heart")
                })

                Spacer()

                Button(action: {
                    appModel.appState = playing ? .stopped : .playing
                }, label: {
                    Image(systemName: playing ? "pause" : "play")
                })

                Spacer()

                Button(action: {

                }, label: {
                    Image(systemName: "info.circle")
                })
            }
        }
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
