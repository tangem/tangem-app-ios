//
//  YieldModuleActiveContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct YieldModuleActiveContentView: View {
    // MARK: - View Model

    @ObservedObject var viewModel: YieldModuleActiveViewModel

    // MARK: - View Body

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary
                .edgesIgnoringSafeArea(.all)

            scrollView
        }
    }

    // MARK: - Sub Views

    private var scrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                topSection

                notificationsView

                marketingBanner

                rewardsBanner

                myFundsSection

                bottomSection
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .safeAreaInset(edge: .top) {
            navTitleView
                .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            button
                .padding(.horizontal, 16)
                .background(ListFooterOverlayShadowView())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private var navTitleView: some View {
        BottomSheetHeaderView(title: Localization.commonYieldMode, trailing: { NavigationBarButton.close(action: viewModel.onBackButtonTap) })
    }

    private var button: some View {
        MainButton(settings: .init(
            title: Localization.yieldModuleStopEarning,
            style: .secondary,
            action: viewModel.onShowStopEarningSheet
        ))
        .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.disableButton)
    }

    private var notificationsView: some View {
        ForEach(viewModel.earnInfoNotifications) { notification in
            YieldModuleBottomSheetNotificationBannerView(params: notification)
        }
    }

    @ViewBuilder
    private var marketingBanner: some View {
        if let standaloneMarketingBanners = viewModel.standaloneMarketingBanners {
            StandaloneMarketingBannersView(banners: standaloneMarketingBanners)
        }
    }

    @ViewBuilder
    private var rewardsBanner: some View {
        if let rewardsBannerData = viewModel.rewardsBannerData {
            YieldModuleRewardsBannerView(viewData: rewardsBannerData, claimAction: viewModel.onClaimTap)
        }
    }

    @ViewBuilder
    private var apyTrendView: some View {
        switch viewModel.apyTrend {
        case .increased, .loading:
            Triangle()
                .fill(DesignSystem.Color.iconAccentBlue)
                .frame(width: 12, height: 10)
                .shimmerPlaceholder(viewModel.apyState == .loading)

        case .none:
            EmptyView()
        }
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            currentApyTitle
                .padding(.bottom, 4)

            HStack {
                apyTrendView

                LoadableTextView(
                    state: viewModel.apyState,
                    font: Fonts.Bold.title2,
                    textColor: DesignSystem.Color.textAccentBlue,
                    loaderSize: .init(width: 100, height: 28)
                )
            }
            .padding(.bottom, 16)

            Separator(color: DesignSystem.Color.borderSecondary)
                .padding(.bottom, 8)
                .padding(.horizontal, -16)

            YieldModuleEarnInfoChartContainer(kind: .legacy, state: viewModel.chartState)

            if let promoBonusText = viewModel.promoBonusText {
                Separator(color: DesignSystem.Color.borderSecondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, -16)

                promoBonusButton(text: promoBonusText)
            }
        }
        .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary)
    }

    private var currentApyTitle: some View {
        HStack(spacing: 4) {
            Text(Localization.yieldModuleEarnSheetCurrentApyTitle)
                .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)

            if viewModel.apyBreakdown != nil {
                apyInfoButton
            }
        }
    }

    private var apyInfoButton: some View {
        SwiftUI.Button(action: viewModel.onApyInfoTap) {
            Assets.infoCircle16.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                // Grows the 16pt icon to the 44pt accessibility touch target without moving the layout.
                .padding(Constants.apyInfoTouchPadding)
                .contentShape(Rectangle())
        }
        .padding(-Constants.apyInfoTouchPadding)
        .accessibilityLabel(Localization.yieldModuleAboutApySheetTitle)
    }

    private func promoBonusButton(text: String) -> some View {
        SwiftUI.Button(action: viewModel.onPromoBonusTap) {
            HStack(spacing: 12) {
                Assets.Accounts.gift.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconAccentBlue)

                Text(text)
                    .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Assets.chevronRight.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
        }
    }

    private var myFundsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localization.yieldModuleEarnSheetMyFundsTitle)
                .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)

            providerTitle

            myFundsDescription
        }
        .padding(.top, 4)
        .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary)
    }

    private var providerTitle: some View {
        HStack(spacing: 6) {
            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .frame(size: .init(bothDimensions: 20))

            Text(Localization.yieldModuleProvider)
                .style(Fonts.Bold.title2, color: DesignSystem.Color.textPrimary)
        }
    }

    private var myFundsDescription: some View {
        VStack(spacing: 14) {
            Text(viewModel.makeMyFundsSectionText())
                .multilineTextAlignment(.leading)
                .environment(\.openURL, OpenURLAction { _ in
                    viewModel.openReadMore()
                    return .handled
                })

            Separator(color: DesignSystem.Color.borderSecondary)
                .padding(.horizontal, 4)

            YieldFeeSection(
                sectionState: viewModel.availableBalanceState,
                leadingTitle: Localization.yieldModuleEarnSheetAvailableTitle,
                needsBackground: false
            )
        }
    }

    private var bottomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 12) {
                YieldFeeSection(
                    sectionState: .init(feeState: .loaded(text: Localization.yieldModuleTransferModeAutomatic)),
                    leadingTitle: Localization.yieldModuleEarnSheetTransfersTitle,
                    needsBackground: false
                )

                Separator(color: DesignSystem.Color.borderSecondary)
                    .padding(.horizontal, 4)

                YieldFeeSection(
                    sectionState: viewModel.minimalAmountState,
                    leadingTitle: Localization.yieldModuleFeePolicySheetMinAmountTitle,
                    needsBackground: false
                )

                Separator(color: DesignSystem.Color.borderSecondary)
                    .padding(.horizontal, 4)

                YieldFeeSection(
                    sectionState: viewModel.estimatedFeeState,
                    leadingTitle: Localization.commonEstimatedFee,
                    needsBackground: false,
                    leadingTextAccessoryView: {
                        if viewModel.estimatedFeeState.isHighlighted {
                            Assets.redCircleWarning20Outline.image
                        }
                    }
                )
            }
            .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary)

            if let footerText = viewModel.earInfoFooterText {
                Text(footerText)
                    .padding(.leading, 14)
            }
        }
    }
}

// MARK: - Constants

private extension YieldModuleActiveContentView {
    enum Constants {
        static let apyInfoTouchPadding: CGFloat = 14
    }
}
