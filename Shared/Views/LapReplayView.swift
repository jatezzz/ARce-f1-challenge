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
    @State var presentingSessionModal = false
    
    @State var session: Session

    @State var compareSession: Session? = nil

    @State var presentingEngineInfo = true
    @State var presentingLapInfo = true
    @State var isMeasureActive = false

    @State var showOverlay = true

    @State var captureSelected: Bool = false
    @State var weatherSelected: Bool = false
    @State var commentsSelected: Bool = false
    @State var timeSelected: Bool = false

    @State var sliderValue: Double = 0

    @State private var isAppearing: Bool = false
    
    struct ARVariables{
      static var arView: ARView!
    }
    
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
                if showOverlay {
                    VStack {
                        Spacer()
                        ZStack {
                            HStack(alignment: .bottom) {
                                DataBubbleView(currentData: dataModel.mainParticipant, presentingEngineInfo: $presentingEngineInfo, presentingLapInfo: $presentingLapInfo)
                                    .frame(alignment: .leading)
                                Spacer()
                                if let _ = compareSession {
                                    DataBubbleView(currentData: dataModel.secondarticipant, presentingEngineInfo: $presentingEngineInfo, presentingLapInfo: $presentingLapInfo)
                                        .frame(alignment: .trailing)
                                }
                            }
                            .padding()
                        }
                        if timeSelected {
                            #warning("set max value as session duration")
                            VStack {
                                Slider(value: $sliderValue, in: 0...20)
                                Text("Current slider value: \(sliderValue, specifier: "%.2f")")
                                    .foregroundColor(.white)
                            }
                            .fadeInAnimation(isAnimating: isAppearing)
                            .onAppear {
                                isAppearing = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack {
                        HStack{
                            OverlayButtonsView(captureSelected: $captureSelected, weatherSelected: $weatherSelected, commentsSelected: $commentsSelected, timeSelected: $timeSelected)
                            Spacer()
                        } .padding()
                        Spacer()
                    }
                }

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
                            presentingSessionModal = true
                        } label: {
                            Text("Session Data")
                        }

                        Button {
                            presentingModal = true
                        } label: {
                            Text("Compare")
                        }

                        if let _ = compareSession {
                            #if !os(macOS)
                            Button(role: .destructive) {
                                compareSession = nil
                            } label: {
                                Label("Stop comparing", systemImage: "xmark")
                            }
                            #else
                            Button(action: {
                                compareSession = nil
                            }, label: {
                                Label("Stop comparing", systemImage: "xmark")
                            })
                            #endif
                        }
                    }

                    if showOverlay {
                        Section {
                            Button{
                                presentingEngineInfo = !presentingEngineInfo
                            } label: {
                                Label("Engine", systemImage: presentingEngineInfo ? "checkmark.circle.fill" : "circle")
                            }

                            Button{
                                presentingLapInfo = !presentingLapInfo
                            } label: {
                                Label("Track", systemImage: presentingLapInfo ? "checkmark.circle.fill" : "circle")
                            }
                        }.opacity(showOverlay ? 1 : 0)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .sheet(isPresented: $presentingModal) {
                    DriversListView(presentedAsModal: self.$presentingModal, session: session, selectedSession: $compareSession)
                }
                .sheet(isPresented: $presentingSessionModal) {
                    SessionDetailView(presentedAsModal: self.$presentingSessionModal)
                }
                .opacity(showOverlay ? 1 : 0)
            }
            #if !os(macOS)
            ToolbarItemGroup(placement: .bottomBar) {
                let playing = appModel.appState == .playing

                Button{
                    showOverlay = !showOverlay
                } label: {
                    Label("Engine", systemImage: showOverlay ? "eye.fill" : "eye")
                }

                Spacer()

                Button(action: {
                    appModel.appState = playing ? .stopped : .playing
                }, label: {
                    Image(systemName: playing ? "pause" : "play")
                })

                Spacer()

                Menu {
                    Button {

                    } label: {
                        Label("Zoom In", systemImage: "plus.magnifyingglass")
                    }

                    Button {

                    } label: {
                        Label("Zoom Out", systemImage: "minus.magnifyingglass")
                    }

                    Button {

                    } label: {
                        Label("Record", systemImage: "record.circle")
                    }

                    Button {
                        dataModel.toogleMeasureFunctionality()
                    } label: {
                        Label(dataModel.isInMeasureFunctionality ? "Cancel measure" : "Measure", systemImage: "ruler")
                    }

                    Section {
                        Button{
                            isMeasureActive = !isMeasureActive
                        } label: {
                            Label("Manipulate", systemImage: isMeasureActive ? "checkmark.circle.fill" : "circle")
                        }
                    }.opacity(showOverlay ? 1 : 0)

                } label: {
                    Image(systemName: "gear")
                }
                .opacity(showOverlay ? 1 : 0)

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
