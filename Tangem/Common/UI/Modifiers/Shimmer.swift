//
//  Shimmer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct Shimmer: ViewModifier {
    @State var isInitialState: Bool = true
    private let duration: CGFloat

    init(duration: CGFloat = 1) {
        self.duration = duration
    }

    public func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(
                    gradient: .init(colors: [.black, .black.opacity(0.4), .black]),
                    startPoint: isInitialState ? .init(x: -0.5, y: -0.5) : .init(x: 1, y: 1),
                    endPoint: isInitialState ? .init(x: 0, y: 0) : .init(x: 1.5, y: 1.5)
                )
            }
            .animation(.linear(duration: duration).repeatForever(autoreverses: false), value: isInitialState)
            .onAppear {
                isInitialState = false
            }
    }
}
