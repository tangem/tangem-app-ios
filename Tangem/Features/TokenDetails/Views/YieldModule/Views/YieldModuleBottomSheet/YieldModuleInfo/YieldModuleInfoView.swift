//
//  YieldModuleInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization
import TangemAssets

struct YieldModuleInfoView: View {
    @ObservedObject var viewModel: YieldModuleInfoViewModel

    // MARK: - View Body

    var body: some View {
        contentView.animation(.contentFrameUpdate, value: viewModel.viewState)
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
            content: { mainContent },
            contentTopPadding: contentTopPadding
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var contentTopPadding: CGFloat {
        switch viewModel.viewState {
        case .earnInfo:
            8
        default:
            24
        }
    }

    private var title: String? {
        switch viewModel.viewState {
        case .earnInfo:
            nil
        case .approve:
            Localization.yieldModuleApproveSheetTitle
        case .stopEarning:
            Localization.yieldModuleStopEarningSheetTitle
        }
    }

    private var subtitle: String? {
        switch viewModel.viewState {
        case .earnInfo:
            nil
        case .approve:
            Localization.yieldModuleApproveSheetSubtitle
        case .stopEarning:
            Localization.yieldModuleStopEarningSheetDescription(viewModel.walletModel.tokenItem.currencySymbol)
        }
    }

    private var mainButton: MainButton {
        switch viewModel.viewState {
        case .earnInfo:
            .init(settings: .init(
                title: Localization.yieldModuleDisableButton,
                style: .secondary,
                action: ctaButtonAction
            ))
        case .approve, .stopEarning:
            .init(settings: .init(
                title: Localization.commonConfirm,
                icon: .trailing(Assets.tangemIcon),
                style: .primary,
                isLoading: viewModel.isProcessingRequest,
                isDisabled: !viewModel.isActionButtonAvailable,
                action: ctaButtonAction
            ))
        }
    }

    @ViewBuilder
    private var topContent: some View {
        switch viewModel.viewState {
        case .earnInfo:
            EmptyView()
        case .stopEarning:
            stopEarningTopContent
        case .approve:
            approveTopContent
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.viewState {
        case .earnInfo:
            YieldModuleActiveСontentView(
                apyState: viewModel.apyState,
                apyTrend: viewModel.apyTrend,
                minAmountState: viewModel.minimalAmountState,
                chartState: viewModel.chartState,
                estimatedFeeState: viewModel.estimatedFeeState,
                availableBalanceState: viewModel.availableBalanceState,
                notifications: viewModel.earnInfoNotifications,
                transferMode: Localization.yieldModuleTransferModeAutomatic,
                readMoreUrl: viewModel.readMoreURL,
                myFundsSectionText: viewModel.makeMyFundsSectionText(),
                earInfoFooterText: viewModel.earInfoFooterText
            )

        case .approve:
            YieldFeeSection(
                sectionState: viewModel.networkFeeState,
                leadingTitle: Localization.commonNetworkFeeTitle,
                linkTitle: Localization.commonReadMore,
                url: viewModel.readMoreURL,
                notification: viewModel.networkFeeNotification
            )

        case .stopEarning:
            YieldFeeSection(
                sectionState: viewModel.networkFeeState,
                leadingTitle: Localization.commonNetworkFeeTitle,
                linkTitle: Localization.commonReadMore,
                url: viewModel.readMoreURL,
                notification: viewModel.networkFeeNotification
            )
        }
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.viewState {
        case .earnInfo:
            viewModel.onShowStopEarningSheet
        case .stopEarning:
            { viewModel.onActionTap(action: .stop) }
        case .approve:
            { viewModel.onActionTap(action: .approve) }
        }
    }
}

// MARK: - Top Content

private extension YieldModuleInfoView {
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

// MARK: - Header

private extension YieldModuleInfoView {
    private func earnInfoHeader(status: String) -> some View {
        ZStack {
            BottomSheetHeaderView(title: "", trailing: { CircleButton.close { viewModel.onCloseTap() } })

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
    func makeHeader(viewState: YieldModuleInfoViewModel.ViewState) -> some View {
        switch viewState {
        case .stopEarning, .approve:
            BottomSheetHeaderView(title: "", leading: { CircleButton.back { viewModel.onBackTap() } })
        case .earnInfo:
            earnInfoHeader(status: viewModel.activityState.description)
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
