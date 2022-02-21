//
//  View+Extension.swift
//  F1 mac app
//
//  Created by Alejandro Ulloa on 2022-02-20.
//

import SwiftUI

extension View {

    func fadeInAnimation(isAnimating: Bool) -> some View {
        self
            .blur(radius: isAnimating ? 0 : 10)
            .opacity(isAnimating ? 1 : 0)
            .scaleEffect(isAnimating ? 1 : 0.5)
            .animation(.easeIn(duration: 0.2), value: isAnimating)

    }

    func fadeOutAnimation(isAnimating: Bool) -> some View {
        self
            .blur(radius: !isAnimating ? 0 : 10)
            .opacity(!isAnimating ? 1 : 0)
            .scaleEffect(!isAnimating ? 1 : 0.5)
            .animation(.easeOut(duration: 0.2), value: !isAnimating)
    }
}
