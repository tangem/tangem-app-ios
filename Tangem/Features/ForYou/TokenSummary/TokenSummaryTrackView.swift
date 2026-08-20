//
//  TokenSummaryTrackView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TokenSummaryTrackView: View {
    /// The row keeps a fixed height so the Markets summary card and its skeleton, which is sized off this value,
    /// stay aligned.
    static let height: CGFloat = 16

    let score: TokenSummaryScore?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackFill)
                    .frame(height: Constants.trackHeight)
                    .frame(maxHeight: .infinity, alignment: .center)

                if let score {
                    thumb
                        .position(
                            x: centerX(forPosition: score.normalizedPosition, width: proxy.size.width),
                            y: proxy.size.height / 2
                        )
                }
            }
        }
        .frame(height: Self.height)
    }

    private var thumb: some View {
        Circle()
            .fill(DesignSystem.Color.iconPrimary)
            .frame(width: Constants.thumbSize, height: Constants.thumbSize)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
    }

    private func centerX(forPosition position: Double, width: CGFloat) -> CGFloat {
        Constants.thumbSize / 2 + CGFloat(position) * (width - Constants.thumbSize)
    }

    private var trackFill: AnyShapeStyle {
        guard score != nil else {
            return AnyShapeStyle(DesignSystem.Color.bgDisabled)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    DesignSystem.Color.bgStatusError,
                    DesignSystem.Color.bgStatusInfo,
                    DesignSystem.Color.bgStatusSuccess,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Constants

private extension TokenSummaryTrackView {
    enum Constants {
        static let trackHeight: CGFloat = 6
        static let thumbSize: CGFloat = 10
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 32) {
        TokenSummaryTrackView(score: TokenSummaryScore(value: 4, count: 5))
        TokenSummaryTrackView(score: TokenSummaryScore(value: -3, count: 5))
        TokenSummaryTrackView(score: nil)
    }
    .padding(24)
    .background(DesignSystem.Color.bgSecondary)
}
