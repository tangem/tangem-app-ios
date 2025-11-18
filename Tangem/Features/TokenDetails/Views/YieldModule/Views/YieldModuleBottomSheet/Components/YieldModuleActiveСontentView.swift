//
//  YieldModuleActiveСontentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

extension YieldModuleInfoView {
    struct YieldModuleActiveСontentView: View {
        // MARK: - Properties

        let apyState: LoadableTextView.State
        let apyTrend: YieldModuleInfoViewModel.ApyTrend
        let minAmountState: YieldFeeSectionState
        let chartState: YieldChartContainerState
        let estimatedFeeState: YieldFeeSectionState
        let availableBalanceState: YieldFeeSectionState
        let notifications: [YieldModuleNotificationBannerParams]
        let transferMode: String
        let readMoreUrl: URL
        let myFundsSectionText: AttributedString
        let earInfoFooterText: AttributedString?

        // MARK: - View Body

        var body: some View {
            VStack(spacing: 8) {
                topSection

                notificationsView

                myFundsSection

                bottomSection
            }
        }

        // MARK: - Sub Views

        private var notificationsView: some View {
            ForEach(notifications) { notification in
                YieldModuleBottomSheetNotificationBannerView(params: notification)
            }
        }

        @ViewBuilder
        private var apyTrendView: some View {
            switch apyTrend {
            case .increased, .loading:
                Triangle()
                    .fill(Colors.Icon.accent)
                    .frame(width: 12, height: 10)
                    .skeletonable(isShown: apyState == .loading)

            case .none:
                EmptyView()
            }
        }

        private var topSection: some View {
            VStack(alignment: .leading, spacing: .zero) {
                Text(Localization.yieldModuleEarnSheetCurrentApyTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 4)

                HStack {
                    apyTrendView

                    LoadableTextView(
                        state: apyState,
                        font: Fonts.Bold.title2,
                        textColor: Colors.Text.accent,
                        loaderSize: .init(width: 100, height: 28)
                    )
                }
                .padding(.bottom, 16)

                Separator(color: Colors.Stroke.primary)
                    .padding(.bottom, 8)
                    .padding(.horizontal, -16)

                YieldModuleEarnInfoChartContainer(state: chartState)
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var myFundsSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.yieldModuleEarnSheetMyFundsTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                providerTitle

                myFundsDescription
            }
            .padding(.top, 4)
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var providerTitle: some View {
            HStack(spacing: 6) {
                Assets.YieldModule.yieldModuleAaveLogo.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 20))

                Text(Localization.yieldModuleProvider)
                    .style(Fonts.Bold.title2, color: Colors.Text.primary1)
            }
        }

        private var myFundsDescription: some View {
            VStack(spacing: 14) {
                Text(myFundsSectionText)
                    .multilineTextAlignment(.leading)

                Separator(color: Colors.Stroke.primary)
                    .padding(.horizontal, 4)

                YieldFeeSection(
                    sectionState: availableBalanceState,
                    leadingTitle: Localization.yieldModuleEarnSheetAvailableTitle,
                    needsBackground: false,
                    url: readMoreUrl
                )
            }
        }

        private var bottomSection: some View {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 12) {
                    YieldFeeSection(
                        sectionState: .init(feeState: .loaded(text: transferMode)),
                        leadingTitle: Localization.yieldModuleEarnSheetTransfersTitle,
                        needsBackground: false
                    )

                    Separator(color: Colors.Stroke.primary)
                        .padding(.horizontal, 4)

                    YieldFeeSection(
                        sectionState: minAmountState,
                        leadingTitle: Localization.yieldModuleFeePolicySheetMinAmountTitle,
                        needsBackground: false
                    )

                    Separator(color: Colors.Stroke.primary)
                        .padding(.horizontal, 4)

                    YieldFeeSection(
                        sectionState: estimatedFeeState,
                        leadingTitle: Localization.commonEstimatedFee,
                        needsBackground: false,
                        leadingTextAccessoryView: {
                            if estimatedFeeState.isHighlighted {
                                Assets.redCircleWarning20Outline.image
                            }
                        }
                    )
                }
                .defaultRoundedBackground(with: Colors.Background.action)

                if let earInfoFooterText {
                    Text(earInfoFooterText)
                        .padding(.leading, 14)
                }
            }
        }
    }
}
