//
//  Sessions.swift
//  F1 mac app
//
//  Created by Bogdan Farca on 23.09.2021.
//

import SwiftUI

struct MainView: View {
    @StateObject var dataModel = SessionsDataModel()
    @StateObject var appModel = AppModel.shared
        
    var body: some View {
        NavigationView {
            if appModel.appState == .loadingSessions {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                renderSessionsList()
                    .toolbar {
                        ToolbarItemGroup() {
                            Button { dataModel.loadSessions() }
                                label: { Text("Reload") }
                        }
                    }
                    .navigationTitle("F1 Sessions")
            }
    
            renderMessage()
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private func renderMessage() -> some View {
        switch appModel.appState {
            case .loadingSessions:
                VStack(spacing: 10) {
                    Image(systemName: "cloud")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .opacity(0.5)
                    
                    Text("Loading sessions from Oracle Cloud")
                }
                
            case .waitToLoadTrack:
                VStack(spacing: 10) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .opacity(0.5)
                    
                    Text("Select your session from the left pane")
                }
                
            case let .error(msg):
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                        .opacity(0.5)
                    
                    Text("Error: \(msg)")
                }
            default: EmptyView()
        }
    }
    
    @ViewBuilder
    private func renderSessionsList() -> some View {
        List {
            ForEach(dataModel.sessions.sorted(by: { $0.sessionTime > $1.sessionTime  }), id: \.mSessionid) { session in
                renderSessionRow(session)
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    @ViewBuilder
    private func renderSessionRow(_ session: Session) -> some View {
        NavigationLink(destination: LapReplayView(session: session)) {
            VStack(alignment: .leading) {
                Text("Session by \(session.driver)")
                Group {
                    Text("\(session.sessionTime)")
                    Text("\(session.laps) laps")
                }
                .font(.system(size: 10, weight: .light))
                .opacity(0.7)
            }
        }
    }
}

struct Sessions_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
