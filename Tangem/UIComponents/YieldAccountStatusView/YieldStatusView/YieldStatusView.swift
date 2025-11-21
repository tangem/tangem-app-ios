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
import TangemAccessibilityIdentifiers

struct YieldStatusView: View {
    // MARK: - View Model

    @ObservedObject
    var viewModel: YieldStatusViewModel

    // MARK: - View Body

    var body: some View {
        switch viewModel.state {
        case .loading, .closing:
            content
        case .active:
            Button(action: viewModel.onTapAction) {
                content
            }
        }
    }

    // MARK: - Sub Views

    private var content: some View {
        HStack(spacing: .zero) {
            aaveLogo

            VStack(alignment: .leading, spacing: 4) {
                title
                descriptionText
            }
            .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            trailingView
        }
        .defaultRoundedBackground(verticalPadding: 14)
    }

    private var aaveLogo: some View {
        Assets.YieldModule.yieldModuleAaveLogo.image
            .resizable()
            .scaledToFit()
            .frame(size: .init(bothDimensions: 36))
            .padding(.trailing, 12)
    }

    @ViewBuilder
    private var title: some View {
        Text(viewModel.title)
            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
    }

    @ViewBuilder
    private var descriptionText: some View {
        switch viewModel.state {
        case .loading:
            Text(Localization.yieldModuleTokenDetailsEarnNotificationProcessing)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        case .active:
            Text(Localization.yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceSubtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        case .closing:
            Text(Localization.yieldModuleStopEarning)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    private var loadingIndicator: some View {
        TimelineView(.animation) { context in
            let progress = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
            let degrees = progress * 360

            Circle()
                .trim(from: 0.0, to: 0.8)
                .stroke(Colors.Icon.accent, style: StrokeStyle(lineWidth: 2, lineCap: .square))
                .frame(width: 20, height: 20)
                .padding(.horizontal, 2)
                .rotationEffect(.degrees(degrees))
        }
    }

    private var yellowWarningSign: some View {
        Assets.attention.image
    }

    private var blueWarningSign: some View {
        Assets.blueCircleWarning.image
            .resizable()
            .frame(size: .init(bothDimensions: 24))
    }

    private var chevron: some View {
        Assets.chevronRightWithOffset24.image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
            .frame(size: .init(bothDimensions: 24))
    }

    @ViewBuilder
    private var trailingWarningSignView: some View {
        switch viewModel.warning {
        case .none:
            EmptyView()
        case .approveNeeded:
            yellowWarningSign
        case .hasUndepositedAmounts:
            blueWarningSign
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.state {
        case .active:
            HStack(spacing: 2) {
                trailingWarningSignView
                chevron
            }
        case .loading, .closing:
            loadingIndicator
        }
    }
}
