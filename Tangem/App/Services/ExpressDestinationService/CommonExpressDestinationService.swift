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
    private let expressRepository: ExpressRepository

    init(
        pendingTransactionRepository: ExpressPendingTransactionRepository,
        walletModelsManager: WalletModelsManager,
        expressRepository: ExpressRepository
    ) {
        self.pendingTransactionRepository = pendingTransactionRepository
        self.walletModelsManager = walletModelsManager
        self.expressRepository = expressRepository
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getDestination(source: WalletModel) async throws -> WalletModel? {
        try await expressRepository.updatePairs(for: source)

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

        // If user has wallets with balance then sort they
        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: { ($0.fiatValue ?? 0) > ($1.fiatValue ?? 0) })

        // Start searching destination with available providers
        for wallet in sortedWallets {
            let pair = ExpressManagerSwappingPair(source: source, destination: wallet)
            let availableProviders = try await expressRepository.getAvailableProviders(for: pair)
            if !availableProviders.isEmpty {
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
