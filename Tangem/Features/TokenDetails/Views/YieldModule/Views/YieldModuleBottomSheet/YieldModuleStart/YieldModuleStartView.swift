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
            notificationBanner: bannerParams,
            buttonTopPadding: buttonTopPadding
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var buttonTopPadding: CGFloat {
        if viewModel.notificationBannerParams != nil {
            return 24
        }

        return 32
    }

    private var bannerParams: YieldModuleViewConfigs.YieldModuleNotificationBannerParams? {
        if case .startEarning = viewModel.viewState {
            return viewModel.notificationBannerParams
        }

        return nil
    }

    private var title: String? {
        switch viewModel.viewState {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetTitle
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
        case .startEarning:
            Localization.yieldModuleStartEarningSheetDescription(viewModel.walletModel.tokenItem.name)
        case .feePolicy:
            Localization.yieldModuleFeePolicySheetDescription(viewModel.walletModel.tokenItem.name)
        }
    }

    @ViewBuilder
    private var subtitleFooter: some View {
        switch viewModel.viewState {
        case .rateInfo:
            rateInfoSubtitleFooter
        case .feePolicy, .startEarning:
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

    private var mainButton: MainButton {
        switch viewModel.viewState {
        case .rateInfo, .feePolicy:
            .init(settings: .init(
                title: Localization.commonGotIt,
                style: .secondary,
                isDisabled: !viewModel.isButtonEnabled,
                action: ctaButtonAction
            ))
        case .startEarning:
            .init(settings: .init(
                title: Localization.yieldModuleStartEarning,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                isLoading: viewModel.isProcessingStartRequest,
                isDisabled: !viewModel.isButtonEnabled,
                action: ctaButtonAction,
            ))
        }
    }

    @ViewBuilder
    private var topContent: some View {
        switch viewModel.viewState {
        case .rateInfo, .feePolicy:
            EmptyView()
        case .startEarning:
            LendingPairIcon(tokenId: viewModel.walletModel.tokenItem.id, iconsSize: IconViewSizeSettings.tokenDetails.iconSize)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.viewState {
        case .rateInfo:
            YieldModuleRateInfoChartContainer(state: viewModel.chartState)
                .task {
                    await viewModel.fetchChartData()
                }

        case .startEarning:
            YieldFeeSection(
                leadingTitle: Localization.commonNetworkFeeTitle,
                state: viewModel.networkFeeState,
                footerText: Localization.yieldModuleStartEarningSheetNextDeposits,
                linkTitle: Localization.yieldModuleStartEarningSheetFeePolicy,
                url: nil,
                isLinkActive: viewModel.isNavigationToFeePolicyEnabled,
                onLinkTapAction: viewModel.onShowFeePolicy
            )
            .onAppear {
                viewModel.fetchFees()
            }

        case .feePolicy:
            YieldModuleFeePolicyView(
                tokenFeeState: viewModel.tokenFeeState,
                maximumFeeState: viewModel.maximumFeeState,
                minimalAmountState: viewModel.minimalAmountState,
                blockchainName: viewModel.walletModel.tokenItem.blockchain.displayName,
            )
        }
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.viewState {
        case .startEarning:
            viewModel.onStartEarnTap
        case .rateInfo:
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
            BottomSheetHeaderView(title: "", leading: { CircleButton.back { viewModel.onBackAction() } })
        case .startEarning, .rateInfo:
            BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.onCloseTap() } })
        }
    }
}
