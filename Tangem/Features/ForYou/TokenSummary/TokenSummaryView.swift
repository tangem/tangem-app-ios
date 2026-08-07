//
//  TokenSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TokenSummaryView: View {
    /// Sentiment to render. `nil` means the token data couldn't be loaded.
    let outlook: TokenSummaryOutlook?
    let lastUpdated: Date?

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 10

    var body: some View {
        VStack(spacing: 40) {
            header
            track
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 40)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var header: some View {
        if let outlook {
            VStack(spacing: 4) {
                Text(Localization.tokenSummaryTitle)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

                Text(outlook.title)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

                if let lastUpdated {
                    Text(Localization.tokenSummaryLastUpdateSubtitle(Self.dateFormatter.string(from: lastUpdated)))
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .padding(.top, 4)
                }
            }
            .multilineTextAlignment(.center)
        } else {
            Text(Localization.tokenSummaryCanNotLoadToken)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var track: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackFill)
                    .frame(height: trackHeight)
                    .frame(maxHeight: .infinity, alignment: .center)

                if let outlook {
                    thumb
                        .offset(x: outlook.position * (proxy.size.width - thumbSize))
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .frame(height: thumbSize)
    }

    private var thumb: some View {
        Circle()
            .fill(DesignSystem.Color.iconPrimary)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
    }

    private var trackFill: AnyShapeStyle {
        guard outlook != nil else {
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

// MARK: - Previews

#Preview {
    let date = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 20))

    return VStack(spacing: 40) {
        TokenSummaryView(outlook: .positive, lastUpdated: date)
        TokenSummaryView(outlook: .negative, lastUpdated: date)
        TokenSummaryView(outlook: .neutral, lastUpdated: date)
        TokenSummaryView(outlook: nil, lastUpdated: nil)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.Tangem.Surface.level2)
}
