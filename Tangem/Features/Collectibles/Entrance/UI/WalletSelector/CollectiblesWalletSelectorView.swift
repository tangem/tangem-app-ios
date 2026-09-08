//
//  CollectiblesWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct CollectiblesWalletSelectorView: View {
    private let viewModel: CollectiblesWalletSelectorViewModel

    init(viewModel: CollectiblesWalletSelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: viewModel.accountSelectorViewModel.state.navigationBarTitle,
                backAction: nil,
                closeAction: viewModel.close
            ),
            content: { content }
        )
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            config.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

// MARK: - Content

private extension CollectiblesWalletSelectorView {
    // MARK: - View properties

    var content: some View {
        VStack(spacing: 0) {
            AccountSelectorView(viewModel: viewModel.accountSelectorViewModel, style: .addTokenRedesigned)

            cancelButton
        }
    }

    var cancelButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.commonCancel),
            accessibilityLabel: Localization.commonCancel,
            action: viewModel.close
        )
        .styleType(.secondary(.default))
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.horizontal, Metrics.buttonHorizontalPadding)
        .padding(.bottom, Metrics.buttonBottomPadding)
    }
}

// MARK: - Metrics

private extension CollectiblesWalletSelectorView {
    enum Metrics {
        static let buttonHorizontalPadding: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 12
    }
}
