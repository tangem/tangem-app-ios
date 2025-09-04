//
//  YieldPromoBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct YieldPromoBottomSheetView: View {
    @ObservedObject var viewModel: YieldPromoBottomSheetViewModel

    // MARK: - View Body

    var body: some View {
        contentView.animation(.contentFrameUpdate, value: viewModel.flow)
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var contentView: some View {
        SheetContainer(
            title: title,
            subtitle: subtitle,
            buttonStyle: buttonStyle,
            toolBarTitle: { toolBarTitle },
            topContent: { topContent },
            subtitleFooter: { subtitleFooter },
            content: { mainContent },
            closeAction: closeAction,
            backAction: backAction,
            buttonAction: ctaButtonAction
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var title: String {
        switch viewModel.flow {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetTitle
        case .startYearing:
            Localization.yieldModuleStartEarningSheetTitle
        case .feePolicy:
            Localization.yieldModuleFeePolicySheetTitle
        case .approve:
            Localization.yieldModuleApproveSheetTitle
        case .stopEarning:
            Localization.yieldModuleStopEarningSheetTitle
        }
    }

    private var subtitle: String {
        switch viewModel.flow {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetDescription
        case .startYearing(let params):
            Localization.yieldModuleStartEarningSheetDescription(params.tokenName)
        case .feePolicy(let params):
            Localization.yieldModuleFeePolicySheetDescription(params.tokenName)
        case .approve:
            Localization.yieldModuleApproveSheetSubtitle
        case .stopEarning(let params):
            Localization.yieldModuleStopEarningSheetDescription(params.tokenName)
        }
    }

    @ViewBuilder
    private var subtitleFooter: some View {
        switch viewModel.flow {
        case .rateInfo:
            rateInfoSubtitleFooter
        case .feePolicy, .startYearing, .approve, .stopEarning:
            EmptyView()
        }
    }

    private var rateInfoSubtitleFooter: some View {
        HStack(spacing: .zero) {
            Text(Localization.yieldModuleRateInfoSheetPoweredBy)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.trailing, 6)

            Assets.YieldModule.aaveLogo.image.padding(.trailing, 2)

            Text(Localization.yieldModuleProvider.uppercased()).style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var buttonStyle: CallToActionButtonStyle {
        switch viewModel.flow {
        case .rateInfo, .feePolicy:
            .gray(title: Localization.commonGotIt)
        case .startYearing:
            .blackWithTangemIcon(title: Localization.yieldModuleStartEarningSheetTitle)
        case .approve:
            .blackWithTangemIcon(title: Localization.commonConfirm)
        case .stopEarning:
            .blackWithTangemIcon(title: Localization.commonConfirm)
        }
    }

    private var toolBarTitle: some View {
        EmptyView()
    }

    @ViewBuilder
    private var topContent: some View {
        switch viewModel.flow {
        case .rateInfo, .feePolicy:
            EmptyView()
        case .startYearing(let params):
            startEarningTopContent(icon: params.tokenIcon)
        case .stopEarning:
            stopEarningTopContent
        case .approve:
            approveTopContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.flow {
        case .rateInfo(let params):
            InterestRateInfo(lastYearReturns: params.lastYearReturns)

        case .startYearing(let params):
            StartEarningView(
                fee: params.networkFee,
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
            FeePolicyView(currentFee: params.currentFee, maximumFee: params.maximumFee, blockchainName: params.blockchainName)

        case .approve(let params):
            ApproveView(fee: params.networkFee, readMoreAction: {})

        case .stopEarning(let params):
            StopEarningView(fee: params.networkFee, readMoreAction: {})
        }
    }

    private var closeAction: (() -> Void)? {
        switch viewModel.flow {
        case .rateInfo, .startYearing:
            viewModel.onCloseTapAction
        case .feePolicy, .stopEarning, .approve:
            nil
        }
    }

    private var backAction: (() -> Void)? {
        switch viewModel.flow {
        case .rateInfo, .startYearing:
            nil
        case .feePolicy, .stopEarning, .approve:
            viewModel.onBackAction
        }
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.flow {
        case .rateInfo, .startYearing:
            viewModel.onCloseTapAction
        case .feePolicy, .stopEarning, .approve:
            viewModel.onBackAction
        }
    }
}

private extension YieldPromoBottomSheetView {
    private var approveTopContent: some View {
        ZStack {
            Circle()
                .fill(Colors.Icon.accent.opacity(0.1))
                .frame(size: .init(bothDimensions: 56))

            Assets.YieldModule.yieldCheckMark.image
                .resizable()
                .frame(size: .init(bothDimensions: 26))
        }
    }

    private var stopEarningTopContent: some View {
        ZStack {
            Circle()
                .fill(Colors.Icon.attention.opacity(0.1))
                .frame(size: .init(bothDimensions: 56))

            Assets.WalletConnect.yellowWarningCircle.image
                .resizable()
                .frame(size: .init(bothDimensions: 26))
        }
    }

    private func startEarningTopContent(icon: Image) -> some View {
        HStack(spacing: 8) {
            icon
                .resizable()
                .frame(size: .init(bothDimensions: 48))

            Assets.YieldModule.aaveLogo.image
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
