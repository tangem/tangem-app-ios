//
//  TokenSummaryGaugeView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TokenSummaryGaugeView: View {
    let state: TokenSummaryGaugeState
    let lastUpdated: Date?

    private var score: TokenSummaryScore? {
        if case .score(let score) = state {
            return score
        }

        return nil
    }

    var body: some View {
        VStack(spacing: 40) {
            header
            track
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var header: some View {
        switch state {
        case .score(let score):
            VStack(spacing: 4) {
                Text(Localization.tokenSummaryTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

                Text(score.outlook.title)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                if let lastUpdated {
                    Text(Localization.tokenSummaryLastUpdateSubtitle(Self.dateFormatter.string(from: lastUpdated)))
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .padding(.top, 4)
                }
            }
            .multilineTextAlignment(.center)
        case .outlookUnavailable:
            message(Localization.tokenSummaryOutlookIsNotAvailable)
        case .dataUnavailable:
            message(Localization.tokenSummaryCanNotLoadToken)
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)
            .multilineTextAlignment(.center)
    }

    private var track: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let midY = proxy.size.height / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackFill)
                    .frame(height: Constants.trackHeight)
                    .frame(maxHeight: .infinity, alignment: .center)

                if let score {
                    ForEach(Array(0 ..< score.tickCount), id: \.self) { index in
                        tick
                            .position(
                                x: centerX(forPosition: Double(index) / Double(score.tickCount - 1), width: width),
                                y: midY
                            )
                    }

                    thumb
                        .position(x: centerX(forPosition: score.normalizedPosition, width: width), y: midY)
                }
            }
        }
        .frame(height: Constants.tickSize.height)
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Constants

private extension TokenSummaryGaugeView {
    enum Constants {
        static let trackHeight: CGFloat = 6
        static let thumbSize: CGFloat = 10
        static let tickSize = CGSize(width: 1, height: 16)
    }
}

// MARK: - Previews

#Preview {
    let date = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 20))

    return VStack(spacing: 40) {
        TokenSummaryGaugeView(state: .score(TokenSummaryScore(value: 4, count: 5)), lastUpdated: date)
        TokenSummaryGaugeView(state: .score(TokenSummaryScore(value: -3, count: 5)), lastUpdated: date)
        TokenSummaryGaugeView(state: .score(TokenSummaryScore(value: 1, count: 5)), lastUpdated: date)
        TokenSummaryGaugeView(state: .score(TokenSummaryScore(value: 0, count: 1)), lastUpdated: date)
        TokenSummaryGaugeView(state: .outlookUnavailable, lastUpdated: nil)
        TokenSummaryGaugeView(state: .dataUnavailable, lastUpdated: nil)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.Tangem.Surface.level2)
}
