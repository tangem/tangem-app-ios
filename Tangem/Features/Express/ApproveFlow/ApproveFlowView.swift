//
//  ApproveFlowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets
import TangemUIUtils

struct ApproveFlowView: View {
    @ObservedObject private var viewModel: ApproveFlowViewModel

    init(viewModel: ApproveFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        FeeSelectorBottomSheetContainerView(
            state: viewModel.state.hashValue,
            showsButton: viewModel.state.showsButton,
            verticalSwipeBehavior: .init(target: .sheet, threshold: 100),
            button: { approveButton },
            headerContent: { headerView },
            descriptionContent: { descriptionView },
            mainContent: { mainContentView }
        )
        .alert(item: $viewModel.alert) { $0.alert }
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var approveButton: some View {
        if case .approve(let approveViewModel) = viewModel.state {
            if viewModel.confirmTransactionPolicy.needsHoldToConfirm {
                HoldToConfirmButton(
                    title: Localization.commonApprove,
                    isLoading: approveViewModel.isLoading,
                    isDisabled: approveViewModel.mainButtonIsDisabled,
                    action: approveViewModel.didTapApprove
                )
            } else {
                MainButton(
                    title: Localization.commonApprove,
                    icon: approveViewModel.tangemIconProvider.getMainButtonIcon(),
                    isLoading: approveViewModel.isLoading,
                    isDisabled: approveViewModel.mainButtonIsDisabled,
                    action: approveViewModel.didTapApprove
                )
            }
        }
    }

    private var headerView: some View {
        BottomSheetHeaderView(
            title: viewModel.state.title,
            leading: { leadingHeaderButton() },
            trailing: { trailingHeaderButton() }
        )
    }

    @ViewBuilder
    private var descriptionView: some View {
        if let subtitle = viewModel.state.subtitle {
            Text(subtitle)
                .environment(\.openURL, OpenURLAction { _ in
                    viewModel.openLearnMore()
                    return .handled
                })
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.state {
        case .approve(let approveViewModel):
            ApproveView(viewModel: approveViewModel)
        case .feeTokenSelection(let tokensViewModel):
            FeeSelectorTokensView(viewModel: tokensViewModel)
        }
    }

    @ViewBuilder
    private func leadingHeaderButton() -> some View {
        if viewModel.state.headerButtonAction == .back {
            NavigationBarButton.back(action: viewModel.dismissFeeTokenSelection)
        }
    }

    @ViewBuilder
    private func trailingHeaderButton() -> some View {
        if viewModel.state.headerButtonAction == .close {
            NavigationBarButton.close(action: {
                if case .approve(let approveViewModel) = viewModel.state {
                    approveViewModel.didTapCancel()
                }
            })
        }
    }
}
