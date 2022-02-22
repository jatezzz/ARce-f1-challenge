//
//  SessionDetailView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-21.
//

import SwiftUI

struct SessionDetailView: View {

    @Binding var presentedAsModal: Bool

    var body: some View {
        Text("Title")
            .font(.title)
            .frame(alignment: .leading)
            .padding()
        Form {
            Section(header: Text("Section header")) {
                Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            }
        }



        Button("Return") { self.presentedAsModal = false }
                .font(.body.bold())
                .padding()
    }
}
