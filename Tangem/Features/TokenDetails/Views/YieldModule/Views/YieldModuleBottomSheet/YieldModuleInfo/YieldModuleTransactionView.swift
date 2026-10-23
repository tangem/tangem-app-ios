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
            title: viewModel.action.title,
            subtitle: viewModel.action.description,
            button: mainButton,
            header: { header },
            topContent: { topContent },
            content: { content },
        )
        .transition(.content)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = .color(Colors.Background.tertiary)
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    // MARK: - Sub Views

    private var content: some View {
        YieldFeeSection(
            sectionState: viewModel.networkFeeState,
            leadingTitle: Localization.commonNetworkFeeTitle,
            linkTitle: Localization.commonReadMore,
            onLinkTapAction: viewModel.openReadMore,
            notification: viewModel.networkFeeNotification
        )
    }

    private var topContent: some View {
        viewModel.action.icon.image
            .resizable()
            .scaledToFit()
            .frame(size: .init(bothDimensions: 56))
    }

    private var mainButton: some View {
        SigningActionButtonView(
            type: viewModel.signingActionButtonType,
            title: viewModel.action.buttonTitle,
            isLoading: viewModel.isProcessingRequest,
            isDisabled: !viewModel.isActionButtonAvailable,
            action: viewModel.onActionTap
        )
        .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.confirmButton)
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
