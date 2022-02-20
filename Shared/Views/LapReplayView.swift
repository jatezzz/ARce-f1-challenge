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

    @State var presentingModal = false
    
    @State var session: Session

    @State var compareSession: Session? = nil

    @State var presentingEngineInfo = true
    @State var presentingLapInfo = false

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
                            if let _ = compareSession {
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

                    Section {
                        Button {
                            presentingModal = true
                        } label: {
                            Text("Compare")
                        }

                        if let _ = compareSession {
                            Button(role: .destructive) {
                                compareSession = nil
                            } label: {
                                Label("Stop comparing", systemImage: "xmark")
                            }
                        }
                    }

                    Section {
                        Button{
                            presentingEngineInfo = !presentingEngineInfo
                        } label: {
                            Label("Engine", systemImage: presentingEngineInfo ? "checkmark.circle" : "circle")
                        }

                        Button{
                            presentingLapInfo = !presentingLapInfo
                        } label: {
                            Label("Track", systemImage: presentingLapInfo ? "checkmark.circle" : "circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .sheet(isPresented: $presentingModal) {
                    DriversListView(presentedAsModal: self.$presentingModal, session: session, selectedSession: $compareSession)
                }
            }
#if !os(macOS)
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

                Button {

                } label: {
                    Image(systemName: "info.circle")
                }

            }
            #endif
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
