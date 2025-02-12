//
//  Shimmer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct Shimmer: ViewModifier {
    @State private var isAppeared: Bool = false

    // It doesn't matter which color we use in gradient
    // Because we use `.mask` in `body` and it just add transparency to center of the view
    private let gradient = Gradient(colors: [.black, .black.opacity(0.4), .black])
    private let activeAnimation = Animation.linear(duration: 1).repeatForever(autoreverses: false)
    private let stopAnimation = Animation.linear(duration: 0)
    private let idlePoints: GradientPoints
    private let animationPoints: GradientPoints
    private var gradientPoints: GradientPoints {
        isAppeared ? animationPoints : idlePoints
    }

    init(bandSize: CGFloat = 1) {
        let topLeading = UnitPoint.topLeading // 0, 0
        let bottomLeading = UnitPoint.bottomTrailing // 1, 1

        idlePoints = GradientPoints(start: UnitPoint(x: topLeading.x - bandSize, y: topLeading.y - bandSize), end: topLeading)
        animationPoints = GradientPoints(start: bottomLeading, end: UnitPoint(x: bottomLeading.x + bandSize, y: bottomLeading.y + bandSize))
    }

    public func body(content: Content) -> some View {
        content
            .mask {
                LinearGradient(gradient: gradient, startPoint: gradientPoints.start, endPoint: gradientPoints.end)
            }
            .transaction { transaction in
                transaction.animation = isAppeared ? activeAnimation : .none
            }
            .onAppear {
                guard !isAppeared else {
                    return
                }

                isAppeared = true
            }
            .onDisappear {
                guard isAppeared else {
                    return
                }

                isAppeared = false
            }
    }
}

private extension Shimmer {
    struct GradientPoints: Equatable, Animatable {
        let start: UnitPoint
        let end: UnitPoint
    }
}
