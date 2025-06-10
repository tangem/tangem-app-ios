//
//  CommonExpressDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

struct CommonExpressDestinationService {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    private let walletModelsManager: WalletModelsManager
    private let expressRepository: ExpressRepository

    init(
        walletModelsManager: WalletModelsManager,
        expressRepository: ExpressRepository
    ) {
        self.walletModelsManager = walletModelsManager
        self.expressRepository = expressRepository
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getDestination(source: any WalletModel) async throws -> any WalletModel {
        let availablePairs = await expressRepository.getPairs(from: source)
        let searchableWalletModels = walletModelsManager.walletModels.filter { wallet in
            let isNotSource = wallet.id != source.id
            let isAvailable = expressAvailabilityProvider.canSwap(tokenItem: wallet.tokenItem)
            let isNotCustom = !wallet.isCustom
            let hasPair = availablePairs.contains(where: { $0.destination == wallet.expressCurrency })

            return isNotSource && isAvailable && isNotCustom && hasPair
        }
        .map { walletModel -> (walletModel: any WalletModel, fiatBalance: Decimal?) in
            (walletModel: walletModel, fiatBalance: walletModel.fiatAvailableBalanceProvider.balanceType.value)
        }

        ExpressLogger.info(self, "has searchableWalletModels: \(searchableWalletModels.map(\.walletModel.expressCurrency))")

        if let lastSwappedWallet = searchableWalletModels.first(where: { isLastTransactionWith(walletModel: $0.walletModel) }) {
            ExpressLogger.info(self, "select lastSwappedWallet: \(lastSwappedWallet.walletModel.expressCurrency)")
            return lastSwappedWallet.walletModel
        }

        let walletModelsWithPositiveBalance = searchableWalletModels.filter { ($0.fiatBalance ?? 0) > 0 }

        // If all wallets without balance
        if walletModelsWithPositiveBalance.isEmpty, let first = searchableWalletModels.first {
            ExpressLogger.info(self, "has a zero wallets with positive balance then selected: \(first.walletModel.expressCurrency)")
            return first.walletModel
        }

        // If user has wallets with balance then sort they
        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: {
            ($0.fiatBalance ?? 0) > ($1.fiatBalance ?? 0)
        })

        // Start searching destination with available providers
        if let maxBalanceWallet = sortedWallets.first {
            ExpressLogger.info(self, "selected maxBalanceWallet: \(maxBalanceWallet.walletModel.expressCurrency)")
            return maxBalanceWallet.walletModel
        }

        ExpressLogger.info(self, "couldn't find acceptable wallet")
        throw ExpressDestinationServiceError.destinationNotFound
    }
}

// MARK: - Private

private extension CommonExpressDestinationService {
    func isLastTransactionWith(walletModel: any WalletModel) -> Bool {
        let transactions = pendingTransactionRepository.transactions
        let lastCurrency = transactions.last?.destinationTokenTxInfo.tokenItem.expressCurrency

        return walletModel.expressCurrency == lastCurrency
    }
}

extension CommonExpressDestinationService: CustomStringConvertible {
    var description: String {
        "ExpressDestinationService"
    }
}
