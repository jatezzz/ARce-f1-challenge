//
//  OverlayButtonsView.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-20.
//

import SwiftUI

struct OverlayButtonsView: View {

    @State private var selectedIndex = 0
    @State private var showAlert: Bool = false

    @Binding var captureSelected: Bool
    @Binding var weatherSelected: Bool
    @Binding var commentsSelected: Bool
    @Binding var timeSelected: Bool


    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            OverlayButton(imageName: "camera", deselectAll: deselectAll, action: captureAction, observable: $captureSelected)
                .alert("ScreenShot taken", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                }
            OverlayButton(imageName: "cloud.sun", deselectAll: deselectAll, action: {}, observable: $weatherSelected)
            OverlayButton(imageName: "digitalcrown.horizontal.arrow.counterclockwise", deselectAll: deselectAll, action: {}, observable: $timeSelected)
        }
    }

    func deselectAll() {
        captureSelected = false
        weatherSelected = false
        commentsSelected = false
        timeSelected = false
    }

    func captureAction() {
        LapDataModel.shared.arView.snapshot(saveToHDR: false) { (image) in
            let compressedImage = UIImage(data: (image?.pngData())!)
            UIImageWriteToSavedPhotosAlbum(compressedImage!, nil, nil, nil)
            showAlert = true
        }
    }
}

struct OverlayButton: View {

    @State private var isAppearing: Bool = false

    @State var imageName: String
    @State var deselectAll: () -> Void
    @State var action: () -> Void
    
    @Binding var observable: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Button {
                action()
                if observable {
                    deselectAll()
                } else {
                    deselectAll()
                    observable = true
                }
            } label: {
                Image(systemName: imageName == "camera" ? "camera" : "\(imageName)\(observable ? ".fill" : "")")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.black)
                    .frame(width: 20, height: 20)

            }
            .padding()
            .background(.gray.opacity(0.6))
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
