//
//  YieldModuleTransactionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct YieldModuleTransactionView: View {
    @ObservedObject var viewModel: YieldModuleTransactionViewModel

    // MARK: - View Body

    var body: some View {
        YieldModuleBottomSheetContainerView(
            title: viewModel.isSelectingFeeToken ? YieldFeeTokenSelector.title : viewModel.action.title,
            subtitle: viewModel.isSelectingFeeToken ? YieldFeeTokenSelector.subtitle : viewModel.action.description,
            button: mainButton,
            header: { header },
            topContent: { topContent },
            content: { content },
        )
        .transition(.content)
        .animation(.contentFrameUpdate, value: viewModel.isSelectingFeeToken)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(DesignSystem.Color.bgPrimary)
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var content: some View {
        if viewModel.isSelectingFeeToken, let feeTokenSelector = viewModel.feeTokenSelector {
            FeeSelectorTokensView(viewModel: feeTokenSelector.feeTokensViewModel)
        } else {
            YieldFeeSection(
                sectionState: viewModel.networkFeeState,
                leadingTitle: Localization.commonNetworkFeeTitle,
                linkTitle: Localization.commonReadMore,
                onLinkTapAction: viewModel.openReadMore,
                notification: viewModel.networkFeeNotification,
                feeSelector: feeSelector
            )
        }
    }

    private var feeSelector: YieldFeeSectionFeeSelector? {
        viewModel.feeTokenSelector.map { selector in
            YieldFeeSectionFeeSelector(viewModel: selector.feeCompactViewModel, tapAction: viewModel.onFeeTap)
        }
    }

    @ViewBuilder
    private var topContent: some View {
        if !viewModel.isSelectingFeeToken {
            viewModel.action.icon.image
                .resizable()
                .scaledToFit()
                .frame(size: .init(bothDimensions: 56))
        }
    }

    @ViewBuilder
    private var mainButton: some View {
        if !viewModel.isSelectingFeeToken {
            SigningActionButtonView(
                type: viewModel.signingActionButtonType,
                title: viewModel.action.buttonTitle,
                isLoading: viewModel.isProcessingRequest,
                isDisabled: !viewModel.isActionButtonAvailable,
                action: viewModel.onActionTap
            )
            .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.confirmButton)
        }
    }

    private var header: some View {
        BottomSheetHeaderView(title: "", leading: { NavigationBarButton.back(action: viewModel.onBackTap) })
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
