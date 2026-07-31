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
        if let score = state.score {
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
        } else if let message = state.unavailabilityMessage {
            Text(message)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var track: some View {
        TokenSummaryTrackView(score: state.score)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
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
