//
//  FakeTokenItemInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class FakeTokenItemInfoProvider: ObservableObject {
    let pendingTransactionNotifier = PassthroughSubject<(WalletModelId, Bool), Never>()

    var hasPendingTransactions: Bool { false }

    private(set) var viewModels: [TokenItemViewModel] = []

    private var walletModels: [any WalletModel] = []

    init(walletManagers: [FakeWalletManager]) {
        walletModels = walletManagers.flatMap { $0.walletModels }
        viewModels = walletModels.map { walletModel in
            let (id, provider, tokenItem, tokenIconInfo) = TokenItemInfoProviderItemBuilder()
                .mapTokenItemViewModel(from: .default(walletModel))

            return TokenItemViewModel(
                id: id,
                tokenItem: tokenItem,
                tokenIcon: tokenIconInfo,
                infoProvider: provider,
                contextActionsProvider: self,
                contextActionsDelegate: self,
                tokenTapped: modelTapped(with:),
                yieldApyTapped: { _ in }
            )
        }
    }

    func modelTapped(with id: WalletModelId) {
        guard let tappedWalletManager = walletModels.first(where: { $0.id.id == id.id }) else {
            return
        }
        AppLogger.debug("Tapped wallet model: \(tappedWalletManager)")
        Task {
            await tappedWalletManager.update(silent: true, features: .balances)
            AppLogger.debug("Receive new state \(tappedWalletManager.state) for \(tappedWalletManager)")
        }
    }
}

extension FakeTokenItemInfoProvider: TokenItemContextActionsProvider, TokenItemContextActionDelegate {
    func buildContextActions(for tokenItemViewModel: TokenItemViewModel) -> [TokenContextActionsSection] {
        [.init(items: [.copyAddress, .hide])]
    }

    func didTapContextAction(_ action: TokenActionType, for tokenItemViewModel: TokenItemViewModel) {}
}
