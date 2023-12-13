//
//  CommonExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressDestinationService {
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider
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
        let searchableWalletModels = walletModelsManager.walletModels.filter { wallet in
            wallet.id != source.id && swapAvailabilityProvider.canSwap(tokenItem: wallet.tokenItem)
        }

        if let lastTransactionWalletModel = getLastTransactionWalletModel(in: searchableWalletModels) {
            return lastTransactionWalletModel
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

    private func getLastTransactionWalletModel(in searchableWalletModels: [WalletModel]) -> WalletModel? {
        let transactions = pendingTransactionRepository.pendingTransactions

        guard
            let lastTransactionCurrency = transactions.last?.destinationTokenTxInfo.tokenItem.expressCurrency,
            let lastWallet = searchableWalletModels.first(where: { $0.expressCurrency == lastTransactionCurrency })
        else {
            return nil
        }

        return lastWallet
    }
}
