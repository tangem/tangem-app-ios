//
//  TangemButton+Loader.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension TangemButton {
    struct CircularProgressStyle: ProgressViewStyle {
        @State private var isRotating = false

        let size: CGFloat
        let color: Color

        private let lineWidth: CGFloat = SizeUnit.half.value

        func makeBody(configuration: Configuration) -> some View {
            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                .onAppear(perform: {
                    isRotating = true
                })
        }
    }
}
