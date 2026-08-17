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
    /// The ticks are the tallest element, so they set the row height whether or not they are drawn.
    static let height: CGFloat = Constants.tickSize.height

    let score: TokenSummaryScore?
    let showsTicks: Bool

    init(score: TokenSummaryScore?, showsTicks: Bool = true) {
        self.score = score
        self.showsTicks = showsTicks
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let midY = proxy.size.height / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackFill)
                    .frame(height: Constants.trackHeight)
                    .frame(maxHeight: .infinity, alignment: .center)

                if let score {
                    if showsTicks {
                        ticks(for: score, width: width, midY: midY)
                    }

                    thumb
                        .position(x: centerX(forPosition: score.normalizedPosition, width: width), y: midY)
                }
            }
        }
        .frame(height: Self.height)
    }

    @ViewBuilder
    private func ticks(for score: TokenSummaryScore, width: CGFloat, midY: CGFloat) -> some View {
        if score.tickCount > 1 {
            ForEach(0 ..< score.tickCount, id: \.self) { index in
                tick
                    .position(
                        x: centerX(forPosition: Double(index) / Double(score.tickCount - 1), width: width),
                        y: midY
                    )
            }
        }
    }

    private var tick: some View {
        Capsule()
            .fill(DesignSystem.Color.iconPrimary)
            .frame(width: Constants.tickSize.width, height: Constants.tickSize.height)
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
        static let tickSize = CGSize(width: 1, height: 16)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 32) {
        TokenSummaryTrackView(score: TokenSummaryScore(value: 4, count: 5))
        TokenSummaryTrackView(score: TokenSummaryScore(value: -3, count: 5))
        TokenSummaryTrackView(score: TokenSummaryScore(value: 4, count: 5), showsTicks: false)
        TokenSummaryTrackView(score: nil)
    }
    .padding(24)
    .background(DesignSystem.Color.bgSecondary)
}
