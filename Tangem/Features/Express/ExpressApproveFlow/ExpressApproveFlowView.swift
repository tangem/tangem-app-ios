//
//  ExpressApproveFlowView.swift
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

struct ExpressApproveFlowView: View {
    @ObservedObject private var viewModel: ExpressApproveFlowViewModel

    init(viewModel: ExpressApproveFlowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        FeeSelectorBottomSheetContainerView(
            state: viewModel.state.hashValue,
            button: buttonView,
            headerContent: { headerView },
            descriptionContent: { descriptionView },
            mainContent: { mainContentView }
        )
        .alert(item: $viewModel.alert) { $0.alert }
    }

    // MARK: - Sub Views

    private var buttonView: MainButton? {
        switch viewModel.state {
        case .approve(let approveViewModel):
            return MainButton(
                title: Localization.commonApprove,
                icon: approveViewModel.tangemIconProvider.getMainButtonIcon(),
                isLoading: approveViewModel.isLoading,
                isDisabled: approveViewModel.mainButtonIsDisabled,
                action: approveViewModel.didTapApprove
            )
        case .feeTokenSelection:
            return nil
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
                    viewModel.openLearnMoreURL()
                    return .handled
                })
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        switch viewModel.state {
        case .approve(let approveViewModel):
            ExpressApproveView(viewModel: approveViewModel)
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
