//
//  SessionDetailView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-21.
//

import SwiftUI

struct SessionDetailView: View {
    @StateObject var dataModel = LapDataModel.shared
    @Binding var presentedAsModal: Bool

    var body: some View {
        Text(dataModel.trackData.isEmpty ? "" : "\(dataModel.trackData[0].trackId)")
            .font(.title)
            .frame(alignment: .leading)
            .padding()
        Form {
            Section(header: Text("Important Events")) {
                ForEach(dataModel.importantEvents, id: \.self) {
                    Text($0.descrition)
                }

            }
        }



        Button("Return") { self.presentedAsModal = false }
                .font(.body.bold())
                .padding()
    }
}
