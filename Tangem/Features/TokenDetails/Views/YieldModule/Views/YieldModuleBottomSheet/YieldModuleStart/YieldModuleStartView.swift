//
//  YieldModuleStartView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

struct YieldModuleStartView: View {
    @ObservedObject var viewModel: YieldModuleStartViewModel

    // MARK: - View Body

    var body: some View {
        contentView
            .animation(.contentFrameUpdate, value: viewModel.viewState)
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var contentView: some View {
        YieldModuleBottomSheetContainerView(
            title: title,
            subtitle: subtitle,
            button: mainButton,
            header: { makeHeader(viewState: viewModel.viewState) },
            topContent: { topContent },
            subtitleFooter: { subtitleFooter },
            content: { mainContent },
            headerBackgroundColor: sheetBackgroundColor,
            footerBackgroundColor: footerBackgroundColor
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(sheetBackgroundColor)
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var sheetBackgroundColor: Color {
        switch viewModel.viewState {
        case .incentiveRateInfo:
            DesignSystem.Color.bgPrimary
        case .rateInfo, .startEarning, .feePolicy:
            Colors.Background.tertiary
        }
    }

    private var footerBackgroundColor: Color {
        switch viewModel.viewState {
        case .incentiveRateInfo:
            DesignSystem.Color.bgPrimary
        case .rateInfo, .startEarning, .feePolicy:
            Colors.Background.primary
        }
    }

    private var title: String? {
        switch viewModel.viewState {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetTitle
        case .incentiveRateInfo:
            nil
        case .startEarning:
            Localization.yieldModuleStartEarning
        case .feePolicy:
            Localization.yieldModuleFeePolicySheetTitle
        }
    }

    private var subtitle: String? {
        switch viewModel.viewState {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetDescription
        case .incentiveRateInfo:
            nil
        case .startEarning:
            Localization.yieldModuleStartEarningSheetDescription(viewModel.walletModel.tokenItem.currencySymbol)
        case .feePolicy:
            Localization.yieldModuleFeePolicySheetDescription(viewModel.walletModel.tokenItem.currencySymbol)
        }
    }

    @ViewBuilder
    private var subtitleFooter: some View {
        switch viewModel.viewState {
        case .rateInfo:
            rateInfoSubtitleFooter
        case .incentiveRateInfo, .feePolicy, .startEarning:
            EmptyView()
        }
    }

    private var rateInfoSubtitleFooter: some View {
        HStack(spacing: .zero) {
            Text(Localization.yieldModuleRateInfoSheetPoweredBy)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.trailing, 6)

            Assets.YieldModule.yieldModuleAaveLogo.image.padding(.trailing, 2)

            Text(Localization.yieldModuleProvider.uppercased()).style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var mainButton: some View {
        switch viewModel.viewState {
        case .rateInfo, .incentiveRateInfo, .feePolicy:
            MainButton(settings: .init(
                title: Localization.commonGotIt,
                style: .secondary,
                action: ctaButtonAction
            ))
        case .startEarning:
            SigningActionButtonView(
                type: viewModel.signingActionButtonType,
                title: Localization.yieldModuleStartEarning,
                isLoading: viewModel.isProcessingStartRequest,
                isDisabled: !viewModel.isButtonEnabled,
                action: ctaButtonAction
            )
            .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.startEarningButton)
        }
    }

    @ViewBuilder
    private var topContent: some View {
        switch viewModel.viewState {
        case .rateInfo, .incentiveRateInfo, .feePolicy:
            EmptyView()
        case .startEarning:
            LendingPairIcon(tokenId: viewModel.walletModel.tokenItem.id, iconsSize: IconViewSizeSettings.tokenDetails.iconSize)
        }
    }

    private var startEarningView: some View {
        VStack(spacing: 8) {
            YieldFeeSection(
                sectionState: viewModel.networkFeeState,
                leadingTitle: Localization.commonNetworkFeeTitle,
                linkTitle: Localization.yieldModuleStartEarningSheetFeePolicy,
                onLinkTapAction: viewModel.onShowFeePolicy,
                notification: viewModel.networkFeeNotification
            )

            if let params = viewModel.highNetworkFeesNotification {
                YieldModuleBottomSheetNotificationBannerView(params: params)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.viewState {
        case .rateInfo:
            YieldModuleRateInfoChartContainer(state: legacyChartContainerState)
        case .incentiveRateInfo:
            incentiveRateInfoView
        case .startEarning:
            startEarningView
        case .feePolicy:
            YieldModuleFeePolicyView(
                minimalAmountState: viewModel.minimalAmountState,
                estimatedFeeState: viewModel.estimatedFeeState,
                maximumFeeState: viewModel.maximumFeeState,
                footerText: viewModel.feePolicyFooter
            )
        }
    }

    private var incentiveRateInfoView: some View {
        VStack(spacing: 16) {
            TangemSegmentedPicker(
                data: YieldIncentiveChartPeriod.allCases,
                selection: $viewModel.incentivePeriod
            )
            .style(.flexible)
            .showSeparators(false)

            YieldModuleIncentiveChartContainer(
                state: incentiveChartContainerState,
                currentApyFormatted: viewModel.currentIncentiveApyFormatted
            )

            if viewModel.marketIncentive != nil {
                incentiveFooter
                    .padding(.top, 12)
            }
        }
    }

    private var legacyChartContainerState: YieldChartContainerState {
        switch viewModel.rateInfoContent {
        case .legacy(let data):
            .loaded(data)
        case .error:
            .error(action: { viewModel.retryRateInfoChart() })
        case .loading, .incentive, .unavailable:
            .loading
        }
    }

    private var incentiveChartContainerState: YieldModuleIncentiveChartContainer.State {
        switch viewModel.rateInfoContent {
        case .incentive(let data):
            .loaded(data)
        case .unavailable:
            .unavailable
        case .error:
            .error(action: { viewModel.retryRateInfoChart() })
        case .loading, .legacy:
            .loading
        }
    }

    private var incentiveFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.yieldModuleIncentiveChartPoweredByTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.yieldModuleIncentiveChartPoweredByDescription)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.viewState {
        case .startEarning:
            viewModel.onStartEarnTap
        case .rateInfo, .incentiveRateInfo:
            viewModel.onCloseTap
        case .feePolicy:
            viewModel.onBackAction
        }
    }
}

// MARK: - Transition

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}

// MARK: - Animation

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

// MARK: - Header

private extension YieldModuleStartView {
    @ViewBuilder
    func makeHeader(viewState: YieldModuleStartViewModel.ViewState) -> some View {
        switch viewState {
        case .feePolicy:
            BottomSheetHeaderView(title: "", leading: { NavigationBarButton.back(action: viewModel.onBackAction) })
        case .startEarning, .rateInfo:
            BottomSheetHeaderView(title: "", trailing: { NavigationBarButton.close(action: viewModel.onCloseTap) })
        case .incentiveRateInfo:
            BottomSheetHeaderView(
                title: Localization.yieldModuleIncentiveChartSheetTitle,
                trailing: { NavigationBarButton.close(action: viewModel.onCloseTap) }
            )
            .titleFont(DesignSystem.Font.bodyMediumToken.font)
            .verticalPadding(4)
        }
    }
}
