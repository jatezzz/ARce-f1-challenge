//
//  OverlayButtonsView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-20.
//

import SwiftUI

struct OverlayButtonsView: View {

    @State private var selectedIndex = 0

    @Binding var captureSelected: Bool
    @Binding var weatherSelected: Bool
    @Binding var commentsSelected: Bool
    @Binding var timeSelected: Bool


    var body: some View {
        VStack(alignment: .center, spacing: 10) {

            
//            OverlayButton(imageName: "camera", deselectAll: deselectAll, observable: $captureSelected)
            OverlayButton(imageName: "cloud.sun", deselectAll: deselectAll, observable: $weatherSelected)
            OverlayButton(imageName: "bubble.right", deselectAll: deselectAll, observable: $commentsSelected)
            OverlayButton(imageName: "digitalcrown.horizontal.arrow.counterclockwise", deselectAll: deselectAll, observable: $timeSelected)
        }
    }

    func deselectAll() {
        captureSelected = false
        weatherSelected = false
        commentsSelected = false
        timeSelected = false
    }
}

struct OverlayButton: View {

    @State private var isAppearing: Bool = false

    @State var imageName: String
    @State var deselectAll: () -> Void
    @Binding var observable: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Button {
                if observable {
                    deselectAll()
                } else {
                    deselectAll()
                    observable = true
                }
            } label: {
                Image(systemName: "\(imageName)\(observable ? ".fill" : "")")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.black)
                    .frame(width: 20, height: 20)

            }
            .padding()
//            .background(.gray.opacity(0.6))
            .cornerRadius(15)
            .fadeInAnimation(isAnimating: isAppearing)
            .onAppear {
                isAppearing = true
            }
        }
    }
}


//struct OverlayButtonsView_Previews: PreviewProvider {
//    static var previews: some View {
//        OverlayButtonsView()
//    }
//}
