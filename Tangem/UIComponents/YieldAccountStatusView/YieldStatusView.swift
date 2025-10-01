//
//  YieldStatusView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldStatusView: View {
    // MARK: - View State

    let status: Status

    // MARK: - Properties

    @State private var rotation = 0.0
    private let animation: Animation = .linear(duration: 1).speed(1).repeatForever(autoreverses: false)

    // MARK: - Dependencies

    private let balanceFormatter = BalanceFormatter()

    // MARK: - View Body

    var body: some View {
        switch status {
        case .loading, .closing:
            content
        case .active(_, _, _, let tapAction):
            Button(action: tapAction) {
                content
            }
        }
    }

    // MARK: - Sub Views

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                title
                description
            }

            Spacer()

            if case .active(_, _, let isApproveNeeded, _) = status {
                trailingView(isApproveNeeded: isApproveNeeded)
            }
        }
        .defaultRoundedBackground()
    }

    private var title: some View {
        Text(Localization.yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceTitle)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    private var description: some View {
        HStack(spacing: 4) {
            descriptionText

            if case .loading = status {
                loadingIndicator
            }
        }
    }

    private var loadingIndicator: some View {
        Circle()
            .trim(from: 0.0, to: 0.8)
            .stroke(Colors.Icon.accent, style: StrokeStyle(lineWidth: 2, lineCap: .square))
            .frame(width: 12, height: 12)
            .padding(.horizontal, 2)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(animation) {
                    rotation = 360.0
                }
            }
    }

    private var warning: some View {
        Assets.attention20.image
    }

    private var chevron: some View {
        Assets.chevronRightWithOffset24.image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
            .frame(size: .init(bothDimensions: 24))
    }

    @ViewBuilder
    private var descriptionText: some View {
        switch status {
        case .loading:
            Text(Localization.yieldModuleTokenDetailsEarnNotificationProcessing)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

        case .active(let income, let apy, _, _):
            HStack(spacing: 4) {
                Text(balanceFormatter.formatFiatBalance(income, currencyCode: AppConstants.usdCurrencyCode))
                    .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                Text(AppConstants.dotSign)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Text(apy.formatted() + "%" + " " + Localization.yieldModuleTokenDetailsEarnNotificationApy)
                    .style(Fonts.Bold.callout, color: Colors.Text.tertiary)
            }

        case .closing:
            Text(Localization.yieldModuleStopEarning)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)
        }
    }

    private func trailingView(isApproveNeeded: Bool) -> some View {
        HStack(spacing: 2) {
            if isApproveNeeded {
                warning
            }

            chevron
        }
    }
}

extension YieldStatusView {
    enum Status {
        case loading
        case active(income: Decimal, annualYield: Decimal, isApproveNeeded: Bool, tapAction: () -> Void)
        case closing
    }
}
