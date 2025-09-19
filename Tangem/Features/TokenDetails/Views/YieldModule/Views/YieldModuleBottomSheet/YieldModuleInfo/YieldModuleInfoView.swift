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
            notificationBanner: viewModel.notificationBannerParams,
            contentTopPadding: contentTopPadding,
            buttonTopPadding: buttonTopPadding
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
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

    private var horizontalPadding: CGFloat {
        switch viewModel.viewState {
        case .earnInfo:
            0
        default:
            16
        }
    }

    private var buttonTopPadding: CGFloat {
        if viewModel.notificationBannerParams != nil {
            return 24
        }

        switch viewModel.viewState {
        case .earnInfo:
            return 16
        default:
            return 32
        }
    }

    private var title: String? {
        switch viewModel.viewState {
        case .earnInfo:
            nil
        case .approve:
            Localization.yieldModuleApproveSheetTitle
        case .stopEarning:
            Localization.yieldModuleStopEarning
        }
    }

    private var subtitle: String? {
        switch viewModel.viewState {
        case .earnInfo:
            nil
        case .approve:
            Localization.yieldModuleApproveSheetSubtitle
        case .stopEarning(let params):
            Localization.yieldModuleStopEarningSheetDescription(params.tokenName)
        }
    }

    private var mainButton: MainButton {
        switch viewModel.viewState {
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
        case .earnInfo(let params):
            YieldModuleEarnInfoView(params: params)

        case .approve(let params):
            YieldModuleApproveView(params: params)

        case .stopEarning(let params):
            YieldModuleStopEarningView(params: params)
        }
    }

    private var ctaButtonAction: () -> Void {
        switch viewModel.viewState {
        case .earnInfo:
            viewModel.onShowStopEarningSheet
        case .stopEarning:
            viewModel.onStopEarningTap
        case .approve:
            viewModel.onApproveTap
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
        case .earnInfo(let params):
            earnInfoHeader(status: params.status.description)
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
