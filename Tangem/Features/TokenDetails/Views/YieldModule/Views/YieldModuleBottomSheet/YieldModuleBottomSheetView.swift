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
            button: mainButton,
            header: { makeHeader(flow: viewModel.flow) },
            topContent: { topContent },
            subtitleFooter: { subtitleFooter },
            content: { mainContent },
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

    private var mainButton: MainButton {
        switch viewModel.flow {
        case .rateInfo, .feePolicy:
            .init(settings: .init(title: Localization.commonGotIt, style: .secondary, action: ctaButtonAction))
        case .startEarning:
            .init(settings: .init(
                title: Localization.yieldModuleStartEarning,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                action: ctaButtonAction
            ))
        }
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
            YieldModuleStartEarningView(networkFee: params.networkFee, showFeePolicyAction: viewModel.onShowFeePolicyTap)

        case .feePolicy(let params):
            YieldModuleFeePolicyView(currentFee: params.networkFee, maximumFee: params.maximumFee, blockchainName: params.blockchainName)
        }
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.flow {
        case .startEarning:
            viewModel.onStartEarningTap
        case .rateInfo:
            viewModel.onCloseTapAction
        case .feePolicy:
            viewModel.onBackAction
        }
    }
}

private extension YieldModuleBottomSheetView {
    private func startEarningTopContent(icon: Image) -> some View {
        ZStack {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .offset(x: -16)

            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Colors.Background.tertiary)
                        .frame(width: 50, height: 50)
                )
                .offset(x: 16)
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
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

// MARK: - Header

private extension YieldModuleBottomSheetView {
    @ViewBuilder
    func makeHeader(flow: YieldModuleBottomSheetViewModel.Flow) -> some View {
        switch flow {
        case .feePolicy:
            BottomSheetHeaderView(title: "", leading: { CircleButton.back { viewModel.onBackAction() } })
        case .startEarning, .rateInfo:
            BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.onCloseTapAction() } })
        }
    }
}
