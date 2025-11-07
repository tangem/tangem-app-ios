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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository
    @Injected(\.expressPairsRepository) private var expressPairsRepository: ExpressPairsRepository

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getSource(destination: any ExpressInteractorDestinationWallet) async throws -> any ExpressInteractorSourceWallet {
        guard let source = await getExpressInteractorWallet(base: destination, searchType: .source) else {
            throw ExpressDestinationServiceError.sourceNotFound(destination: destination)
        }

        return source
    }

    func getDestination(source: any ExpressInteractorSourceWallet) async throws -> any ExpressInteractorSourceWallet {
        guard let destination = await getExpressInteractorWallet(base: source, searchType: .destination) else {
            throw ExpressDestinationServiceError.destinationNotFound(source: source)
        }

        return destination
    }
}

// MARK: - Private

private extension CommonExpressDestinationService {
    func getExpressInteractorWallet(base: any ExpressInteractorDestinationWallet, searchType: SearchType) async -> (any ExpressInteractorSourceWallet)? {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return nil
        }

        let walletModelsManager = userWalletModel.walletModelsManager
        let availablePairs = await expressPairsRepository.getPairs(from: base.tokenItem.expressCurrency)
        let searchableWalletModels = walletModelsManager.walletModels.filter { wallet in
            let isNotSource = wallet.id != base.id
            let isAvailable = expressAvailabilityProvider.canSwap(tokenItem: wallet.tokenItem)
            let isNotCustom = !wallet.isCustom
            let hasPair = availablePairs.contains(where: { $0.destination == wallet.tokenItem.expressCurrency.asCurrency })

            return isNotSource && isAvailable && isNotCustom && hasPair
        }
        .map { walletModel -> (walletModel: any WalletModel, fiatBalance: Decimal?) in
            (walletModel: walletModel, fiatBalance: walletModel.fiatAvailableBalanceProvider.balanceType.value)
        }

        ExpressLogger.info(self, "has searchableWalletModels: \(searchableWalletModels.map(\.walletModel.tokenItem.expressCurrency))")

        if let lastSwappedWallet = searchableWalletModels.first(where: { isLastTransactionWith(walletModel: $0.walletModel, searchType: searchType) }) {
            ExpressLogger.info(self, "select lastSwappedWallet: \(lastSwappedWallet.walletModel.tokenItem.expressCurrency)")
            return lastSwappedWallet.walletModel.asExpressInteractorWallet
        }

        let walletModelsWithPositiveBalance = searchableWalletModels.filter { ($0.fiatBalance ?? 0) > 0 }

        // If all wallets without balance
        if walletModelsWithPositiveBalance.isEmpty, let first = searchableWalletModels.first {
            ExpressLogger.info(self, "has a zero wallets with positive balance then selected: \(first.walletModel.tokenItem.expressCurrency)")
            return first.walletModel.asExpressInteractorWallet
        }

        // If user has wallets with balance then sort they
        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: {
            ($0.fiatBalance ?? 0) > ($1.fiatBalance ?? 0)
        })

        // Start searching destination with available providers
        if let maxBalanceWallet = sortedWallets.first {
            ExpressLogger.info(self, "selected maxBalanceWallet: \(maxBalanceWallet.walletModel.tokenItem.expressCurrency)")
            return maxBalanceWallet.walletModel.asExpressInteractorWallet
        }

        ExpressLogger.info(self, "couldn't find acceptable wallet")
        return nil
    }

    func isLastTransactionWith(walletModel: any WalletModel, searchType: SearchType) -> Bool {
        let transactions = pendingTransactionRepository.transactions

        let lastCurrency = switch searchType {
        case .destination: transactions.last?.destinationTokenTxInfo.tokenItem.expressCurrency
        case .source: transactions.last?.sourceTokenTxInfo.tokenItem.expressCurrency
        }

        return walletModel.tokenItem.expressCurrency == lastCurrency
    }
}

extension CommonExpressDestinationService {
    enum SearchType {
        case source
        case destination
    }
}

extension CommonExpressDestinationService: CustomStringConvertible {
    var description: String {
        "ExpressDestinationService"
    }
}
