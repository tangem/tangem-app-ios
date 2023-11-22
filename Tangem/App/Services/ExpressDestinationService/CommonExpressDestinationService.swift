//
//  CommonExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressDestinationService {
    private let pendingTransactionRepository: ExpressPendingTransactionRepository
    private let walletModelsManager: WalletModelsManager

    init(
        pendingTransactionRepository: ExpressPendingTransactionRepository,
        walletModelsManager: WalletModelsManager
    ) {
        self.pendingTransactionRepository = pendingTransactionRepository
        self.walletModelsManager = walletModelsManager
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getDestination(source: WalletModel) -> WalletModel? {
        return nil

        let searchableWalletModels = walletModelsManager.walletModels.filter { $0.id != source.id }

        if let lastCurrencyTransaction = pendingTransactionRepository.lastCurrencyTransaction(),
           let lastWallet = searchableWalletModels.first(where: { $0.expressCurrency == lastCurrencyTransaction }) {
            return lastWallet
        }

        let walletModelsWithPositiveBalance = searchableWalletModels.filter { ($0.fiatValue ?? 0) > 0 }

        // If all wallets without balance
        if walletModelsWithPositiveBalance.isEmpty, let first = searchableWalletModels.first {
            return first
        }

        // If user has wallets with balance then select with maximum
        if let maxFiatBalance = walletModelsWithPositiveBalance.max(by: { ($0.fiatValue ?? 0) < ($1.fiatValue ?? 0) }) {
            return maxFiatBalance
        }

        return nil
    }
}
