//
//  YieldModuleActiveContentV2View.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct YieldModuleActiveContentV2View: View {
    // MARK: - View Model

    @ObservedObject var viewModel: YieldModuleActiveViewModel

    // MARK: - View Body

    var body: some View {
        ZStack {
            DesignSystem.Color.bgSecondary
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
        .refreshable {
            await viewModel.onPullToRefresh()
        }
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
                .fill(DesignSystem.Color.textBrand)
                .frame(width: 12, height: 10)
                .skeletonable(isShown: viewModel.apyState == .loading)

        case .none:
            EmptyView()
        }
    }

    private var topSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            currentApyTitle
                .padding(.bottom, 4)

            HStack(spacing: 6) {
                apyTrendView

                LoadableTextView(
                    state: viewModel.apyState,
                    font: Constants.apyFont,
                    textColor: DesignSystem.Color.textBrand,
                    loaderSize: .init(width: 100, height: 34)
                )
            }
            .padding(.bottom, 16)

            YieldModuleEarnInfoChartContainer(kind: .incentive, state: viewModel.chartState)

            if let promoBonusText = viewModel.promoBonusText {
                Separator(color: DesignSystem.Color.borderSecondary)
                    .padding(.vertical, 14)

                promoBonusButton(text: promoBonusText)
            }
        }
    }

    private var currentApyTitle: some View {
        HStack(spacing: 4) {
            Text(Localization.yieldModuleEarnSheetCurrentApyTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            if viewModel.apyBreakdown != nil {
                apyInfoButton
            }
        }
    }

    private var apyInfoButton: some View {
        SwiftUI.Button(action: viewModel.onApyInfoTap) {
            DesignSystem.Icons.Info.regular16.image
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
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
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
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

            providerTitle

            myFundsDescription
        }
        .padding(.top, 4)
        .yieldModuleCardBackground()
    }

    private var providerTitle: some View {
        HStack(spacing: 6) {
            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .frame(size: .init(bothDimensions: 20))

            Text(Localization.yieldModuleProvider)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
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
            .yieldModuleCardBackground()

            if let footerText = viewModel.earInfoFooterText {
                Text(footerText)
                    .padding(.leading, 14)
            }
        }
    }
}

// MARK: - Card background

private extension View {
    func yieldModuleCardBackground() -> some View {
        defaultRoundedBackground(
            with: DesignSystem.Color.bgPrimary,
            cornerRadius: YieldModuleActiveContentV2View.Constants.cardCornerRadius
        )
    }
}

// MARK: - Constants

extension YieldModuleActiveContentV2View {
    enum Constants {
        static let apyInfoTouchPadding: CGFloat = 14
        static let cardCornerRadius: CGFloat = 24
        /// `LoadableTextView` takes a plain font, so the heading token is spelled out for it.
        static let apyFont: Font = .system(
            size: DesignSystem.Font.headingMediumToken.fontSize,
            weight: DesignSystem.Font.headingMediumToken.fontWeight
        )
    }
}
