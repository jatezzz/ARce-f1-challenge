// *********************************************************************************************
// Copyright © 2021. Oracle and/or its affiliates. All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at
// http://oss.oracle.com/licenses/upl
// *********************************************************************************************

//
//  Created by Bogdan Farca on 24.09.2021.
//

import RealityKit
import SwiftUI

struct ARViewContainer: NSViewRepresentable {
    func makeNSView(context: Context) -> ARView {
        return LapDataModel.shared.arView
    }
    
    func updateNSView(_ nsView: ARView, context: Context) {}
}
