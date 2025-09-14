//
//  YieldModuleBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct YieldModuleBottomSheetView: View {
    @ObservedObject var viewModel: YieldModuleBottomSheetViewModel

    // MARK: - View Body

    var body: some View {
        contentView.animation(.contentFrameUpdate, value: viewModel.flow)
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var contentView: some View {
        YieldModuleBottomSheetContainerView(
            title: title,
            subtitle: subtitle,
            buttonStyle: buttonStyle,
            toolBarTitle: { toolBarTitle },
            topContent: { topContent },
            subtitleFooter: { subtitleFooter },
            content: { mainContent },
            closeAction: closeAction,
            backAction: backAction,
            buttonAction: ctaButtonAction,
            horizontalPadding: horizontalPadding
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var horizontalPadding: CGFloat {
        16
    }

    private var title: String? {
        switch viewModel.flow {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetTitle
        case .startEarning:
            Localization.yieldModuleStartEarning
        case .feePolicy:
            Localization.yieldModuleFeePolicySheetTitle
        }
    }

    private var subtitle: String? {
        switch viewModel.flow {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetDescription
        case .startEarning(let params):
            Localization.yieldModuleStartEarningSheetDescription(params.tokenName)
        case .feePolicy(let params):
            Localization.yieldModuleFeePolicySheetDescription(params.tokenName)
        }
    }

    @ViewBuilder
    private var subtitleFooter: some View {
        switch viewModel.flow {
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

    private var buttonStyle: CallToActionButtonStyle {
        switch viewModel.flow {
        case .rateInfo, .feePolicy:
            .gray(title: Localization.commonGotIt)
        case .startEarning:
            .blackWithTangemIcon(title: Localization.yieldModuleStartEarning)
        }
    }

    @ViewBuilder
    private var toolBarTitle: some View {
        EmptyView()
    }

    private func earnInfoToolbarTitleView(status: String) -> some View {
        VStack(spacing: .zero) {
            Text(Localization.yieldModuleEarnSheetTitle).style(Fonts.Bold.headline, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Circle()
                    .fill(Colors.Icon.accent)
                    .frame(size: .init(bothDimensions: 8))

                Text(status).style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    private var topContent: some View {
        switch viewModel.flow {
        case .rateInfo, .feePolicy:
            EmptyView()
        case .startEarning(let params):
            startEarningTopContent(icon: params.tokenIcon)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.flow {
        case .rateInfo(let params):
            YieldModuleInterestRateInfoView(lastYearReturns: params.lastYearReturns)

        case .startEarning(let params):
            YieldModuleStartEarningView(
                networkFee: params.networkFee,
                showFeePolicyAction: {
                    viewModel.onShowFeePolicy(
                        params: .init(
                            currentFee: params.networkFee,
                            maximumFee: params.maximumFee,
                            tokenName: params.tokenName,
                            blockchainName: params.blockchainName
                        )
                    )
                }
            )

        case .feePolicy(let params):
            YieldModuleFeePolicyView(
                networkFee: params.currentFee,
                maximumFee: params.maximumFee,
                blockchainName: params.blockchainName
            )
        }
    }

    private var closeAction: (() -> Void)? {
        switch viewModel.flow {
        case .rateInfo, .startEarning:
            viewModel.onCloseTapAction
        case .feePolicy:
            nil
        }
    }

    private var backAction: (() -> Void)? {
        switch viewModel.flow {
        case .rateInfo, .startEarning:
            nil
        case .feePolicy:
            viewModel.onBackAction
        }
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.flow {
        case .rateInfo, .startEarning:
            viewModel.onCloseTapAction
        case .feePolicy:
            viewModel.onBackAction
        }
    }
}

private extension YieldModuleBottomSheetView {
    private func startEarningTopContent(icon: Image) -> some View {
        HStack(spacing: 8) {
            icon
                .resizable()
                .frame(size: .init(bothDimensions: 48))

            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .frame(size: .init(bothDimensions: 48))
        }
    }
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
