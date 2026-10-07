//
//  FloatingSheetRegistry+Polymarket.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemPolymarketUI
import TangemUI

extension FloatingSheetRegistry {
    func registerPolymarketFloatingSheets() {
        register(PolymarketWalletSelectorViewModel.self) { viewModel in
            FloatingSheetContentWithHeader(
                headerConfig: .init(
                    title: Localization.commonChooseWallet,
                    backAction: nil,
                    closeAction: { viewModel.handleViewAction(.close) }
                ),
                content: {
                    AccountSelectorView(viewModel: viewModel.accountSelectorViewModel)
                }
            )
            .floatingSheetConfiguration { configuration in
                configuration.backgroundInteractionBehavior = .tapToDismiss
            }
        }

        register(PolymarketRegionRestrictionViewModel.self) { viewModel in
            PolymarketRegionRestrictionView(viewModel: viewModel)
        }

        register(PolymarketAddFundsSheetViewModel.self) { viewModel in
            PolymarketAddFundsSheetView(viewModel: viewModel)
        }

        register(PolymarketChooseNetworkSheetViewModel.self) { viewModel in
            PolymarketChooseNetworkSheetView(viewModel: viewModel)
        }

        register(PolymarketReceiveSheetViewModel.self) { viewModel in
            PolymarketReceiveSheetView(viewModel: viewModel)
        }
    }
}
