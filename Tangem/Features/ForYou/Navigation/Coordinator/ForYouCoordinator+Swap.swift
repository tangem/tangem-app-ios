//
//  ForYouCoordinator+Swap.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
extension ForYouCoordinator {
    func openTokenSummary(tokenItem: TokenItem, sourceWalletId: UserWalletId?) {
        tokenSummaryViewModel = TokenSummaryViewModel(
            tokenItem: tokenItem,
            onGoToSwap: { [weak self] in
                self?.goToSwap(tokenItem: tokenItem, walletId: sourceWalletId)
            },
            onClose: { [weak self] in
                self?.tokenSummaryViewModel = nil
            }
        )
    }

    /// After summary dismiss (sheet race).
    func onTokenSummaryDismiss() {
        guard let pendingSwap else {
            return
        }

        self.pendingSwap = nil
        presentSwapTokenSelector(tokenItem: pendingSwap.tokenItem, walletId: pendingSwap.walletId)
    }
}

private extension ForYouCoordinator {
    /// No wallet → no swap.
    func goToSwap(tokenItem: TokenItem, walletId: UserWalletId?) {
        pendingSwap = walletId.map { (tokenItem: tokenItem, walletId: $0) }
        tokenSummaryViewModel = nil
    }

    func presentSwapTokenSelector(tokenItem: TokenItem, walletId: UserWalletId) {
        let sourceToken = WalletTokenItem(userWalletId: walletId, tokenItem: tokenItem)

        swapTokenSelectorViewModel = ForYouSwapTokenSelectorViewModel(
            direction: .fromSource(sourceToken),
            preferredWalletId: sourceToken.userWalletId,
            onClose: { [weak self] in
                self?.swapTokenSelectorViewModel = nil
            }
        )
    }
}
