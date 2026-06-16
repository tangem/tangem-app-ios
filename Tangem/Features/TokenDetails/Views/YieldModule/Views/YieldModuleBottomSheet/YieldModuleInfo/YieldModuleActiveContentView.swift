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

struct YieldModuleActiveContentView: View {
    // MARK: - View Model

    @ObservedObject var viewModel: YieldModuleActiveViewModel

    // MARK: - View Body

    var body: some View {
        ZStack {
            Colors.Background.tertiary
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

    private var button: MainButton {
        MainButton(settings: .init(
            title: Localization.yieldModuleStopEarning,
            style: .secondary,
            action: viewModel.onShowStopEarningSheet
        ))
    }

    private var notificationsView: some View {
        ForEach(viewModel.earnInfoNotifications) { notification in
            YieldModuleBottomSheetNotificationBannerView(params: notification)
        }
    }

    @ViewBuilder
    private var apyTrendView: some View {
        switch viewModel.apyTrend {
        case .increased, .loading:
            Triangle()
                .fill(Colors.Icon.accent)
                .frame(width: 12, height: 10)
                .skeletonable(isShown: viewModel.apyState == .loading)

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
                    state: viewModel.apyState,
                    font: Fonts.Bold.title2,
                    textColor: Colors.Text.accent,
                    loaderSize: .init(width: 100, height: 28)
                )
            }
            .padding(.bottom, 16)

            Separator(color: Colors.Stroke.primary)
                .padding(.bottom, 8)
                .padding(.horizontal, -16)

            YieldModuleEarnInfoChartContainer(state: viewModel.chartState)

            if let promoBonusText = viewModel.promoBonusText {
                Separator(color: Colors.Stroke.primary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, -16)

                promoBonusButton(text: promoBonusText)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func promoBonusButton(text: String) -> some View {
        Button(action: viewModel.onPromoBonusTap) {
            HStack(spacing: 12) {
                Assets.Accounts.gift.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)

                Text(text)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .multilineTextAlignment(.leading)

                Spacer()

                Assets.chevronRight.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
        }
    }

    private var bonusPaidOutBanner: some View {
        HStack(spacing: 12) {
            Assets.Send.arrowDown.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(Colors.Icon.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.yieldApyBoostPromoBonusPaidOutTitle)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    .multilineTextAlignment(.leading)

                Text(Localization.yieldApyBoostPromoBonusPaidOutSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Button(action: viewModel.onBonusPaidOutBannerDismiss) {
                Assets.crossBig.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.inactive)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(8)
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
            Text(viewModel.makeMyFundsSectionText())
                .multilineTextAlignment(.leading)
                .environment(\.openURL, OpenURLAction { _ in
                    viewModel.openReadMore()
                    return .handled
                })

            Separator(color: Colors.Stroke.primary)
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

                Separator(color: Colors.Stroke.primary)
                    .padding(.horizontal, 4)

                YieldFeeSection(
                    sectionState: viewModel.minimalAmountState,
                    leadingTitle: Localization.yieldModuleFeePolicySheetMinAmountTitle,
                    needsBackground: false
                )

                Separator(color: Colors.Stroke.primary)
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
            .defaultRoundedBackground(with: Colors.Background.action)

            if let footerText = viewModel.earInfoFooterText {
                Text(footerText)
                    .padding(.leading, 14)
            }
        }
    }
}
