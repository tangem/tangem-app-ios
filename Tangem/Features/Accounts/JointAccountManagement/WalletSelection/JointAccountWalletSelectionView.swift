//
//  JointAccountWalletSelectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountWalletSelectionView: View {
    private let viewModel: JointAccountWalletSelectionViewModel

    init(viewModel: JointAccountWalletSelectionViewModel) {
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

private extension JointAccountWalletSelectionView {
    var content: some View {
        VStack(spacing: .zero) {
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
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.horizontal, Constants.buttonHorizontalPadding)
        .padding(.bottom, Constants.buttonBottomPadding)
    }
}

// MARK: - Constants

private extension JointAccountWalletSelectionView {
    enum Constants {
        static let buttonHorizontalPadding: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 12
    }
}
