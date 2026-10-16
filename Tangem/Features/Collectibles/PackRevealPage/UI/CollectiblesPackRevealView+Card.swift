//
//  CollectiblesPackRevealView+Card.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Kingfisher
import QuartzCore
import SwiftUI
import TangemAssets
import TangemUI

extension CollectiblesPackRevealView {
    struct SpinningCard: View, Animatable {
        var rotation: Double
        let imageURL: URL?
        let cornerRadius: CGFloat
        let perspectiveDistance: CGFloat

        var animatableData: Double {
            get { rotation }
            set { rotation = newValue }
        }

        var body: some View {
            face
                .modifier(PerspectiveRotation(degrees: rotation, distance: perspectiveDistance))
        }
    }
}

// MARK: - Faces

private extension CollectiblesPackRevealView.SpinningCard {
    var face: some View {
        ZStack {
            front
                .opacity(isFacingViewer ? 1 : 0)

            back
                .scaleEffect(x: -1)
                .opacity(isFacingViewer ? 0 : 1)
        }
    }

    var front: some View {
        shape
            .fill(DesignSystem.Color.bgSecondary)
            .overlay {
                KFImage(imageURL)
                    .resizable()
                    .cancelOnDisappear(true)
                    .cacheOriginalImage()
                    .placeholder { Shimmer() }
                    .aspectRatio(contentMode: .fill)
            }
            .clipShape(shape)
    }

    var back: some View {
        // [REDACTED_TODO_COMMENT]
        shape
            .fill(DesignSystem.Color.bgSecondary)
            .overlay {
                Text("BACK")
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)
            }
    }

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var isFacingViewer: Bool {
        let angle = rotation.truncatingRemainder(dividingBy: 360)
        let normalized = angle < 0 ? angle + 360 : angle
        return normalized < 90 || normalized > 270
    }
}

// MARK: - Perspective

private extension CollectiblesPackRevealView.SpinningCard {
    struct PerspectiveRotation: GeometryEffect {
        var degrees: Double
        let distance: CGFloat

        var animatableData: Double {
            get { degrees }
            set { degrees = newValue }
        }

        func effectValue(size: CGSize) -> ProjectionTransform {
            var rotation = CATransform3DIdentity
            rotation.m34 = -1 / distance
            rotation = CATransform3DRotate(rotation, degrees * .pi / 180, 0, 1, 0)

            let toOrigin = CATransform3DMakeTranslation(-size.width / 2, -size.height / 2, 0)
            let back = CATransform3DMakeTranslation(size.width / 2, size.height / 2, 0)

            return ProjectionTransform(CATransform3DConcat(CATransform3DConcat(toOrigin, rotation), back))
        }
    }
}
