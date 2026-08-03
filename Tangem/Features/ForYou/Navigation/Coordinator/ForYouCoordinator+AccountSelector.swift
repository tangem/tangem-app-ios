//
//  ForYouCoordinator+AccountSelector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

@MainActor
extension ForYouCoordinator {
    func openAccountSelector() {
        guard !isAnySheetPresented else {
            return
        }

        analyticsLogger.logAccountFilterOpened()

        let accountsResolver = ForYouAccountSelectionResolver(
            selectionPublisher: selectedAccountsProvider.selectionPublisher
        )

        floatingSheetPresenter.enqueue(
            sheet: ForYouAccountSelectorViewModel(
                userWalletModels: accountsResolver.unlockedWallets,
                selection: selectedAccountsProvider.selection,
                includesAllWallets: accountsResolver.includesAllWallets,
                analyticsLogger: analyticsLogger,
                applySelectionAction: { [selectedAccountsProvider] in
                    selectedAccountsProvider.select($0)
                },
                dismissAction: { [weak self] in
                    self?.closeAccountSelector()
                }
            )
        )
    }

    func closeAccountSelector() {
        floatingSheetPresenter.removeActiveSheet()
    }
}
