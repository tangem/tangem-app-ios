//
//  PolymarketWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

@MainActor
final class PolymarketWalletSelectorViewModel: ObservableObject {
    let accountSelectorViewModel: AccountSelectorViewModel

    private let closeAction: () -> Void

    init(
        userWalletModels: [any UserWalletModel],
        onSelect: @escaping (any UserWalletModel) -> Void,
        onClose: @escaping () -> Void
    ) {
        accountSelectorViewModel = AccountSelectorViewModel(
            userWalletModels: userWalletModels,
            preferredDisplayMode: .wallets,
            onSelect: { onSelect($0.userWalletModel) }
        )
        closeAction = onClose
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            closeAction()
        }
    }
}

// MARK: - ViewAction

extension PolymarketWalletSelectorViewModel {
    enum ViewAction {
        case close
    }
}

// MARK: - FloatingSheetContentViewModel protocol conformance

extension PolymarketWalletSelectorViewModel: FloatingSheetContentViewModel {}
