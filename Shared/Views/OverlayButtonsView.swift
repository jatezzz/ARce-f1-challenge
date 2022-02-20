//
//  OverlayButtonsView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-20.
//

import SwiftUI

struct OverlayButtonsView: View {

    @State private var selectedIndex = 0

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            OverlayButton(image: Image(systemName: "camera"))
            OverlayButton(image: Image(systemName: "cloud.sun"))
            OverlayButton(image: Image(systemName: "bubble.right"))
            OverlayButton(image: Image(systemName: "timer"))
        }
    }
}

struct OverlayButton: View {

    @State var image: Image

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Button {

            } label: {
                image
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.black)
                    .frame(width: 20, height: 20)

            }
            .padding()
            .background(.gray.opacity(0.6))
            .cornerRadius(15)
        }
    }
}


struct OverlayButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayButtonsView()
    }
}
