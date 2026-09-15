//
//  FeedProductGlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct FeedProductGlowView: View {
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let scale = CGSize(
                width: geometry.size.width / Constants.designFrame.width,
                height: geometry.size.height / Constants.designFrame.height
            )

            ZStack(alignment: .topLeading) {
                ForEach(Constants.spots.indices, id: \.self) { index in
                    view(for: Constants.spots[index], scale: scale)
                }
            }
            .opacity(Constants.groupOpacity)
        }
    }
}

// MARK: - Subviews

private extension FeedProductGlowView {
    func view(for spot: Spot, scale: CGSize) -> some View {
        let extent = spot.radius + spot.blur * 2

        return Ellipse()
            .fill(EllipticalGradient(stops: [
                .init(color: color.opacity(spot.opacity), location: 0),
                .init(color: color.opacity(spot.opacity / 2), location: spot.radius / extent),
                .init(color: color.opacity(0), location: 1),
            ]))
            .frame(width: extent * 2 * scale.width, height: extent * 2 * scale.height)
            .offset(x: (spot.center.x - extent) * scale.width, y: (spot.center.y - extent) * scale.height)
    }
}

// MARK: - Auxiliary types

private extension FeedProductGlowView {
    struct Spot {
        let center: CGPoint
        let radius: CGFloat
        let blur: CGFloat
        let opacity: Double
    }
}

// MARK: - Constants

private extension FeedProductGlowView {
    enum Constants {
        static let designFrame = CGSize(width: 186, height: 180)
        static let groupOpacity = 0.5
        static let spots: [Spot] = [
            Spot(center: CGPoint(x: 129, y: 234), radius: 120, blur: 60, opacity: 0.2),
            Spot(center: CGPoint(x: 6, y: 208), radius: 60, blur: 40, opacity: 0.4),
        ]
    }
}
