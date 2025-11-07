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
        .scrollBounceBehaviorBackport(.basedOnSize)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .safeAreaInset(edge: .bottom) {
            button
                .padding(.horizontal, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }

            ToolbarItem(placement: .topBarLeading) {
                navTitleView
            }
        }
    }

    private var backButton: some View {
        ArrowBack(action: viewModel.onBackButtonTap, height: 20)
    }

    private var navTitleView: some View {
        YieldNavTitleView(
            title: Localization.yieldModuleEarnSheetTitle,
            statusText: viewModel.activityState.description
        )
        .padding(.leading, 6)
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
            .padding(.bottom, 8)

            Separator(color: Colors.Stroke.primary)
                .padding(.bottom, 8)

            YieldModuleEarnInfoChartContainer(state: viewModel.chartState)
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
                    leadingTitle: Localization.commonNetworkFeeTitle,
                    needsBackground: false,
                    leadingTextAccessoryView: {
                        if viewModel.estimatedFeeState.isHighlighted {
                            Assets.infoCircle16.image
                                .renderingMode(.template)
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

private struct YieldNavTitleView: View {
    let title: String
    let statusText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 6) {
                Text(statusText)
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)

                Circle()
                    .fill(Colors.Icon.accent)
                    .frame(width: 8, height: 8)
                    .alignmentGuide(.firstTextBaseline) { dimensions in dimensions[VerticalAlignment.center] }
            }
        }
    }
}
