// *********************************************************************************************
// Copyright © 2021. Oracle and/or its affiliates. All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at
// http://oss.oracle.com/licenses/upl
// *********************************************************************************************

//  Filename: DataBubbleView.swift

import SwiftUI

struct DataBubbleView: View {
    
    @StateObject var dataModel = LapDataModel.shared
    
    var body: some View {
        VStack {
            renderTopBubble()
            renderBottomBubble()
        }
        .font(.system(size: 18, design: .monospaced))
        .foregroundColor(.white)
        .padding()
    }
    
    @ViewBuilder
    private func renderTopBubble() -> some View {
        
        let iconColWidth = 25.0
        let valueColWidth = 75.0
        
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "hare")
                    .frame(width: iconColWidth, alignment: .center)
                Text("\(dataModel.currentSpeed)")
                    .fontWeight(.bold)
                    .frame(width: valueColWidth, alignment: .trailing)
                Text("km/h").fontWeight(.ultraLight)
            }
            HStack(spacing: 5) {
                Image(systemName: "speedometer")
                    .frame(width: iconColWidth, alignment: .center)
                Text("\(dataModel.currentRPM)")
                    .fontWeight(.bold)
                    .frame(width: valueColWidth, alignment: .trailing)
                Text("rpm").fontWeight(.ultraLight)
            }
            HStack(spacing: 5) {
                Image(systemName: "gear")
                    .frame(width: iconColWidth, alignment: .center)
                Text("\(dataModel.currentGear)")
                    .fontWeight(.bold)
                    .frame(width: valueColWidth, alignment: .trailing)
            }
            
        }
        .frame(width: 180)
        .padding()
        .background(Color
                        .red
                        .cornerRadius(10)
                        .opacity(0.8)
        )
    }
    
    @ViewBuilder
    private func renderBottomBubble() -> some View {
        
        let titleColWidth = 80.0
        let valueColWidth = 50.0
        
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Text("Lap")
                    .frame(width: titleColWidth, alignment: .trailing)
                Text("\(dataModel.currentLap)")
                    .fontWeight(.bold)
                    .frame(width: valueColWidth, alignment: .trailing)
            }
            HStack(spacing: 5) {
                Text("Sector")
                    .frame(width: titleColWidth, alignment: .trailing)
                Text("\(dataModel.currentSector + 1)")
                    .fontWeight(.bold)
                    .frame(width: valueColWidth, alignment: .trailing)
            }
        }
        .frame(width: 180)
        .padding()
        .background(Color
                        .green
                        .cornerRadius(10)
                        .opacity(0.8)
        )
    }
    

}

struct DataBubble_Previews: PreviewProvider {
    static var previews: some View {
        DataBubbleView()
    }
}
