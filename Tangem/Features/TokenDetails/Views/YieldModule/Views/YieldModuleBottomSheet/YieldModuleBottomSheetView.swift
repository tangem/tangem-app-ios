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
            notificationBanner: notificationBanner,
            contentTopPadding: contentTopPadding,
            horizontalPadding: horizontalPadding,
            buttonTopPadding: buttonTopPadding
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var contentTopPadding: CGFloat {
        switch viewModel.flow {
        case .earnInfo:
            8
        default:
            24
        }
    }

    private var horizontalPadding: CGFloat {
        switch viewModel.flow {
        case .earnInfo:
            0
        default:
            16
        }
    }

    private var buttonTopPadding: CGFloat {
        if notificationBanner != nil {
            return 24
        }

        switch viewModel.flow {
        case .earnInfo:
            return 16
        default:
            return 32
        }
    }

    private var title: String? {
        switch viewModel.flow {
        case .rateInfo:
            Localization.yieldModuleRateInfoSheetTitle
        case .startEarning:
            Localization.yieldModuleStartEarning
        case .feePolicy:
            Localization.yieldModuleFeePolicySheetTitle
        case .earnInfo:
            nil
        case .approve:
            Localization.yieldModuleApproveSheetTitle
        case .stopEarning:
            Localization.yieldModuleStopEarning
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
        case .earnInfo:
            nil
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
        case .feePolicy, .startEarning, .approve, .stopEarning, .earnInfo:
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
        case .earnInfo:
            .init(settings: .init(title: Localization.yieldModuleStopEarning, style: .secondary, action: ctaButtonAction))
        case .approve, .stopEarning:
            .init(settings: .init(
                title: Localization.commonConfirm,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                action: ctaButtonAction
            ))
        }
    }

    @ViewBuilder
    private var topContent: some View {
        switch viewModel.flow {
        case .rateInfo, .feePolicy, .earnInfo:
            EmptyView()
        case .startEarning(let params):
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
            YieldModuleInterestRateInfoView(lastYearReturns: params.lastYearReturns)

        case .startEarning(let params):
            YieldModuleStartEarningView(networkFee: params.networkFee, showFeePolicyAction: { viewModel.onShowFeePolicy(params: params) })

        case .feePolicy(let params):
            YieldModuleFeePolicyView(currentFee: params.networkFee, maximumFee: params.maximumFee, blockchainName: params.blockchainName)

        case .earnInfo(let params):
            YieldModuleEarnInfoView(params: params)

        case .approve(let params):
            YieldModuleApproveView(params: params)

        case .stopEarning(let params):
            YieldModuleStopEarningView(params: params)
        }
    }

    private var notificationBanner: YieldModuleViewConfigs.YieldModuleBottomSheetNotificationBannerParams? {
        viewModel.createNotificationBannerIfNeeded()
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.flow {
        case .startEarning:
            viewModel.onStartEarningTap
        case .rateInfo:
            viewModel.onCloseTapAction
        case .feePolicy:
            viewModel.onBackAction
        case .earnInfo:
            viewModel.onShowStopEarningSheet
        case .stopEarning(let params), .approve(let params):
            params.mainAction
        }
    }
}

// MARK: - Top Content

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
        .frame(height: 56)
    }

    private var approveTopContent: some View {
        Assets.YieldModule.yieldModuleApprove.image
            .resizable()
            .scaledToFit()
            .frame(size: .init(bothDimensions: 56))
    }

    private var stopEarningTopContent: some View {
        Assets.attentionHalo.image
            .resizable()
            .scaledToFit()
            .frame(size: .init(bothDimensions: 56))
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
    private func earnInfoHeader(status: String) -> some View {
        ZStack {
            BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.onCloseTapAction() } })

            VStack(spacing: 3) {
                Text(Localization.yieldModuleEarnSheetTitle)
                    .style(Fonts.Bold.headline, color: Colors.Text.primary1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Colors.Icon.accent)
                        .frame(size: .init(bothDimensions: 8))

                    Text(status)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    func makeHeader(flow: YieldModuleBottomSheetViewModel.Flow) -> some View {
        switch flow {
        case .feePolicy, .stopEarning, .approve:
            BottomSheetHeaderView(title: "", leading: { CircleButton.back { viewModel.onBackAction() } })
        case .startEarning, .rateInfo:
            BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.onCloseTapAction() } })
        case .earnInfo(let params):
            earnInfoHeader(status: params.status.description)
        }
    }
}
