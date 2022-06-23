//
//  SkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

public struct SkeletonView: View {
    @State var isAppeared = false

    // Animatable data - https://developer.apple.com/documentation/swiftui/animatable
    @State var gradientPoints = Constants.idlePoints
    @State var oldShouldAnimateSkeleton: Bool?

    private let secondary: Color = .tangemSkeletonGray
    private let primary: Color = .tangemSkeletonGray2
    private let backgroundOpacity: Double = 1

    private let activeAnimation = Animation.linear(duration: 1).repeatForever(autoreverses: false)
    private let stopAnimation = Animation.linear(duration: 0)

    public init() {}

    public var body: some View {
        ZStack {
            backgroundView

            gradientView  
        }
    }

    var backgroundView: some View {
        Rectangle()
            .foregroundColor(secondary)
            .opacity(backgroundOpacity)
    }

    var gradientView: some View {
        LinearGradient(
            gradient: Gradient(colors: [secondary, primary, secondary]),
            startPoint: gradientPoints.start,
            endPoint: gradientPoints.end
        )
        .opacity(0.8)
        .onAppear {
            guard !isAppeared else {
                return
            }

            isAppeared = true

            withAnimation(activeAnimation) {
                gradientPoints = Constants.animationPoints
            }
        }
        .onDisappear {
            guard isAppeared else {
                return
            }

            isAppeared = false

            withAnimation(stopAnimation) {
                gradientPoints = Constants.idlePoints
            }
        }
    }
}

private extension SkeletonView {
    private enum Constants {
        static let idlePoints = LinearGradientPoints(
            start: UnitPoint.point(position: -1, radius: 0),
            end: UnitPoint.point(position: 0, radius: 0)
        )

        static let animationPoints = LinearGradientPoints(
            start: UnitPoint.point(position: 1, radius: 0),
            end: UnitPoint.point(position: 2, radius: 2)
        )
    }
}

// MARK: Helper extensions

struct LinearGradientPoints: Animatable {
    let start: UnitPoint
    let end: UnitPoint
}

private extension UnitPoint {
    static func point(position: CGFloat, radius: CGFloat) -> UnitPoint {
        return UnitPoint(x: position + radius, y: position + radius)
    }
}
