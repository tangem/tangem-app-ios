//
//  WalletSelectorSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WalletSelectorSheetView: View {
    private let viewModel: WalletSelectorSheetViewModel

    init(viewModel: WalletSelectorSheetViewModel) {
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

private extension WalletSelectorSheetView {
    // MARK: - View properties

    var content: some View {
        AccountSelectorView(viewModel: viewModel.accountSelectorViewModel, style: .addTokenRedesigned)
    }
}
