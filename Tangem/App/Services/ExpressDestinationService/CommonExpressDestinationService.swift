//
//  CommonExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

struct CommonExpressDestinationService {
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider
    private let pendingTransactionRepository: ExpressPendingTransactionRepository
    private let walletModelsManager: WalletModelsManager
    private let expressAPIProvider: ExpressAPIProvider

    init(
        pendingTransactionRepository: ExpressPendingTransactionRepository,
        walletModelsManager: WalletModelsManager,
        expressAPIProvider: ExpressAPIProvider
    ) {
        self.pendingTransactionRepository = pendingTransactionRepository
        self.walletModelsManager = walletModelsManager
        self.expressAPIProvider = expressAPIProvider
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getDestination(source: WalletModel) async throws -> WalletModel? {
        let searchableWalletModels = walletModelsManager.walletModels.filter { wallet in
            let isNotSource = wallet.id != source.id
            let isAvailable = swapAvailabilityProvider.canSwap(tokenItem: wallet.tokenItem)
            let isNotCustom = !wallet.isCustom

            return isNotSource && isAvailable && isNotCustom
        }

        if let lastTransactionWalletModel = getLastTransactionWalletModel(in: searchableWalletModels) {
            return lastTransactionWalletModel
        }

        let walletModelsWithPositiveBalance = searchableWalletModels.filter { ($0.fiatValue ?? 0) > 0 }

        // If all wallets without balance
        if walletModelsWithPositiveBalance.isEmpty, let first = searchableWalletModels.first {
            return first
        }

        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: { ($0.fiatValue ?? 0) > ($1.fiatValue ?? 0) })

        for wallet in sortedWallets {
            let available = try await expressAPIProvider.pairs(from: [source.expressCurrency], to: [wallet.expressCurrency])
            if let providers = available.first?.providers, !providers.isEmpty {
                return wallet
            }
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
