//
//  DriversListView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-19.
//

import SwiftUI

struct DriversListView: View {

    @StateObject var sessionsModel = SessionsDataModel.shared

    @Binding var presentedAsModal: Bool
    @State var session: Session
    @Binding var selectedSession: Session?

    var body: some View {
        VStack {
#if os(macOS)
            List(sessionsModel.sessions.filter { $0.trackId == session.trackId }, id: \.self, selection: $selectedSession) { session in
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
            #else
            List(sessionsModel.sessions.filter { $0.trackId == session.trackId }, id: \.self, selection: $selectedSession) { session in
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
                    .environment(\.editMode, .constant(.active))
            #endif
        }
        Button("dismiss") { self.presentedAsModal = false }
    }
}

//struct PilotsListView_Previews: PreviewProvider {
//    static var previews: some View {
//        PilotsListView(presentedAsModal: <#Binding<Bool>#>, session: <#Session#>)
//    }
//}
