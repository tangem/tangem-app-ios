//
//  ShimmerViewModifier.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

public extension View {
    func shimmer() -> some View {
        modifier(ShimmerViewModifier())
    }
}

// MARK: - Private implementation

private struct ShimmerViewModifier: ViewModifier {
    @Environment(\.isShimmerActive) private var isShimmerActive

    @State private var isAppeared: Bool = false

    /// It doesn't matter which color we use in gradient
    /// Because we use `.mask` in `body` and it just add transparency to center of the view
    private let gradient = Gradient(colors: [.black, .black.opacity(0.4), .black])
    // `repeatForever` animations can't be stopped with `nil` value, see https://stackoverflow.com/questions/59133826/ for details
    private let dummyAnimation = Animation.linear(duration: .zero)
    private let activeAnimation = Animation.linear(duration: 1).repeatForever(autoreverses: false)
    private let idlePoints: GradientPoints
    private let animationPoints: GradientPoints
    private var gradientPoints: GradientPoints {
        isAppeared ? animationPoints : idlePoints
    }

    init(bandSize: CGFloat = 0.5) {
        let topLeading = UnitPoint.topLeading // 0, 0
        let bottomLeading = UnitPoint.bottomTrailing // 1, 1

        idlePoints = GradientPoints(start: UnitPoint(x: topLeading.x - bandSize, y: topLeading.y - bandSize), end: topLeading)
        animationPoints = GradientPoints(start: bottomLeading, end: UnitPoint(x: bottomLeading.x + bandSize, y: bottomLeading.y + bandSize))
    }

    func body(content: Content) -> some View {
        if isShimmerActive {
            content
                .mask {
                    LinearGradient(gradient: gradient, startPoint: gradientPoints.start, endPoint: gradientPoints.end)
                        .animation(isAppeared ? activeAnimation : dummyAnimation, value: isAppeared)
                }
                .drawingGroup()
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
        } else {
            content
        }
    }
}

private extension ShimmerViewModifier {
    struct GradientPoints: Equatable, Animatable {
        let start: UnitPoint
        let end: UnitPoint
    }
}
