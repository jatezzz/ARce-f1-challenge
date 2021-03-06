//
//  DriversListView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-19.
//

import SwiftUI

struct DriversListView: View {

    @StateObject var sessionsModel = SessionsDataModel.shared
    @StateObject var dataModel = LapDataModel.shared

    @Binding var presentedAsModal: Bool
    @State var session: Session
    @Binding var selectedSession: Session?

    var body: some View {
        VStack {
            Text("Select a session to compare:")
                    .font(.title3.bold())
                    .frame(alignment: .leading)
                    .padding()
            #if os(macOS)
            List(sessionsModel.sessions.filter { $0.trackId == session.trackId }, id: \.self, selection: $selectedSession) { session in
                SessionRow(session: session)
                        .onTapGesture {
                            dismissAndSeletSession(session: session)
                        }
            }
            #else
            List(sessionsModel.sessions.filter { $0.trackId == session.trackId }, id: \.self, selection: $selectedSession) { session in
                SessionRow(session: session)
                        .onTapGesture {
                            dismissAndSeletSession(session: session)
                        }
            }
                    .environment(\.editMode, .constant(.active))
            #endif
            Button("Return") { self.presentedAsModal = false }
                    .font(.body.bold())
                    .padding()
        }

    }

    private func dismissAndSeletSession(session: Session) {
        self.presentedAsModal = false
        selectedSession = session
        dataModel.addSession(session: session)
    }
}

struct SessionRow: View {
    var session: Session
    var body: some View {
        HStack {
            Image("driver-placeholder")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color.gray)
                    .clipShape(Circle())
                    .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text(session.driver)
                Text(session.mSessionid)
                        .font(.subheadline)
            }

        }
    }
}

//struct PilotsListView_Previews: PreviewProvider {
//    static var previews: some View {
//        PilotsListView(presentedAsModal: <#Binding<Bool>#>, session: <#Session#>)
//    }
//}
