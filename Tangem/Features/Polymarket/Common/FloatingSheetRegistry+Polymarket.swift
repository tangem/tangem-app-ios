//
//  FloatingSheetRegistry+Polymarket.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

extension FloatingSheetRegistry {
    func registerPolymarketFloatingSheets() {
        register(PolymarketWalletSelectorViewModel.self) { viewModel in
            FloatingSheetContentWithHeader(
                headerConfig: .init(
                    title: Localization.commonChooseWallet,
                    backAction: nil,
                    closeAction: viewModel.onCloseTap
                ),
                content: {
                    AccountSelectorView(viewModel: viewModel.accountSelectorViewModel)
                }
            )
            .floatingSheetConfiguration { configuration in
                configuration.backgroundInteractionBehavior = .tapToDismiss
            }
        }
    }
}
