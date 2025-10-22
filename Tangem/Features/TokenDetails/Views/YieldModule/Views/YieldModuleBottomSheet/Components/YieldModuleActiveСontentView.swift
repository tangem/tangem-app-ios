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
        typealias NetworkFeeAmountState = YieldModuleInfoViewModel.NetworkFeeAmountState

        // MARK: - Properties

        let apyState: LoadableTextView.State
        let apyTrend: YieldModuleInfoViewModel.ApyTrend
        let minAmountState: LoadableTextView.State
        let chartState: YieldChartContainerState
        let networkFeeState: LoadableTextView.State
        let networkFeeAmountState: NetworkFeeAmountState
        let bannerParams: YieldModuleNotificationBannerParams?
        let tokenName: String
        let tokenSymbol: String
        let transferMode: String
        let availableBalance: String
        let readMoreUrl: URL
        let myFundsSectionText: AttributedString

        // MARK: - View Body

        var body: some View {
            VStack(spacing: 8) {
                topSection

                if let bannerParams {
                    YieldModuleBottomSheetNotificationBannerView(params: bannerParams)
                }

                myFundsSection
                bottomSection
            }
        }

        // MARK: - Sub Views

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
                .padding(.bottom, 8)

                Separator(color: Colors.Stroke.primary)
                    .padding(.bottom, 8)

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
                    leadingTitle: Localization.yieldModuleEarnSheetAvailableTitle,
                    state: .loaded(text: availableBalance),
                    footerText: nil,
                    needsBackground: false
                )
            }
        }

        private var bottomSection: some View {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 12) {
                    YieldFeeSection(
                        leadingTitle: Localization.yieldModuleEarnSheetTransfersTitle,
                        state: .loaded(text: transferMode),
                        footerText: nil,
                        needsBackground: false
                    )

                    Separator(color: Colors.Stroke.primary)
                        .padding(.horizontal, 4)

                    YieldFeeSection(
                        leadingTitle: Localization.yieldModuleFeePolicySheetMinAmountTitle,
                        state: minAmountState,
                        footerText: nil,
                        needsBackground: false
                    )

                    Separator(color: Colors.Stroke.primary)
                        .padding(.horizontal, 4)

                    YieldFeeSection(
                        leadingTitle: Localization.commonNetworkFeeTitle,
                        state: networkFeeState,
                        footerText: nil,
                        needsBackground: false,
                        leadingTextAccesoryView: {
                            if case .warning = networkFeeAmountState {
                                Assets.infoCircle16.image
                                    .renderingMode(.template)
                                    .foregroundStyle(Colors.Icon.warning)
                            }
                        }
                    )
                    .leadingTextColor(networkFeeAmountState.networkFeeDescriptionColor)
                    .trailingTextColor(networkFeeAmountState.networkFeeColor)
                }
                .defaultRoundedBackground(with: Colors.Background.action)

                Text(networkFeeAmountState.footerText)
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
                    .padding(.horizontal, 14)

                Text(Localization.yieldModuleFeePolicySheetMinAmountNote("", ""))
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)
                    .padding(.horizontal, 14)
            }
        }
    }
}
