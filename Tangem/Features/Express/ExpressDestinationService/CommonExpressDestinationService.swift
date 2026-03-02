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

    /// [REDACTED_TODO_COMMENT]
    /// [REDACTED_INFO]
    private let userWalletId: UserWalletId?

    init(userWalletId: UserWalletId?) {
        self.userWalletId = userWalletId
    }
}

// MARK: - ExpressDestinationService

extension CommonExpressDestinationService: ExpressDestinationService {
    func getSource(destination: TokenItem) async throws -> any SendSwapableToken {
        guard let source = await getWalletModelPair(base: destination, searchType: .source) else {
            throw ExpressDestinationServiceError.sourceNotFound(destination: destination)
        }

        return source.asSendSwapableToken
    }

    func getDestination(source: TokenItem) async throws -> any SendSwapableToken {
        guard let destination = await getWalletModelPair(base: source, searchType: .destination) else {
            throw ExpressDestinationServiceError.destinationNotFound(source: source)
        }

        return destination.asSendSwapableToken
    }
}

// MARK: - Private

private extension CommonExpressDestinationService {
    func getWalletModelPair(
        base: TokenItem,
        searchType: SearchType
    ) async -> UserWalletInfoWalletModelPair? {
        let walletModels: [UserWalletInfoWalletModelPair] = {
            if let userWalletId, let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) {
                let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
                return walletModels.map { walletModel in
                    UserWalletInfoWalletModelPair(
                        userWalletInfo: userWalletModel.userWalletInfo,
                        walletModel: walletModel
                    )
                }
            }

            return userWalletRepository.models.flatMap { userWalletModel in
                let walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)
                return walletModels.map { walletModel in
                    UserWalletInfoWalletModelPair(
                        userWalletInfo: userWalletModel.userWalletInfo,
                        walletModel: walletModel
                    )
                }
            }
        }()

        let availablePairs = await expressPairsRepository.getPairs(from: base.expressCurrency)
        let searchableWalletModels = walletModels.filter { wallet in
            let isNotSource = wallet.walletModel.id != .init(tokenItem: base)
            let isAvailable = expressAvailabilityProvider.canSwap(tokenItem: wallet.tokenItem)
            let isNotCustom = !wallet.walletModel.isCustom
            let hasPair = availablePairs.contains(where: { $0.destination == wallet.tokenItem.expressCurrency.asCurrency })

            return isNotSource && isAvailable && isNotCustom && hasPair
        }

        ExpressLogger.info(self, "has searchableWalletModels: \(searchableWalletModels.map(\.walletModel.tokenItem.expressCurrency))")

        if let bestPair = selectBestPair(from: searchableWalletModels, searchType: searchType) {
            ExpressLogger.info(self, "selected available wallet: \(bestPair.walletModel.tokenItem.expressCurrency)")
            return bestPair
        }

        // Fallback: if no available token found, try notLoaded tokens.
        // When availablePairs is empty (e.g. due to a network error in updatePairs),
        // we optimistically select a destination anyway — validateSwapPairSupport()
        // in ExpressInteractor will catch genuinely unsupported pairs later.
        let notLoadedWalletModels: [CommonExpressDestinationService.UserWalletInfoWalletModelPair] = walletModels.filter { wallet in
            let isNotSource = wallet.walletModel.id != .init(tokenItem: base)
            let swapState = expressAvailabilityProvider.swapState(for: wallet.tokenItem)
            let isNotAvailable = swapState != .available
            let isNotUnavailable = swapState != .unavailable
            let isNotCustom = !wallet.walletModel.isCustom
            let hasPair = availablePairs.isEmpty || availablePairs.contains(where: { $0.destination == wallet.tokenItem.expressCurrency.asCurrency })

            return isNotSource && isNotAvailable && isNotUnavailable && isNotCustom && hasPair
        }

        if let fallback = selectBestPair(from: notLoadedWalletModels, searchType: searchType) {
            ExpressLogger.info(self, "selected notLoaded fallback: \(fallback.walletModel.tokenItem.expressCurrency)")
            return fallback
        }

        ExpressLogger.info(self, "couldn't find acceptable wallet")
        return nil
    }

    func selectBestPair(
        from walletModels: [UserWalletInfoWalletModelPair],
        searchType: SearchType
    ) -> UserWalletInfoWalletModelPair? {
        let lastSwappedWallet = walletModels.first(where: {
            isLastTransactionWith(walletModel: $0.walletModel, searchType: searchType)
        })

        if let lastSwappedWallet {
            return lastSwappedWallet
        }

        let walletModelsWithPositiveBalance = walletModels.filter { ($0.fiatBalance ?? 0) > 0 }

        if walletModelsWithPositiveBalance.isEmpty {
            return walletModels.first
        }

        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: {
            ($0.fiatBalance ?? 0) > ($1.fiatBalance ?? 0)
        })

        return sortedWallets.first
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
    struct UserWalletInfoWalletModelPair {
        let userWalletInfo: UserWalletInfo
        let walletModel: any WalletModel

        var tokenItem: TokenItem {
            walletModel.tokenItem
        }

        var fiatBalance: Decimal? {
            walletModel.fiatAvailableBalanceProvider.balanceType.value
        }

        var asSendSwapableToken: SendSwapableToken {
            CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                operationType: .swap
            ).makeSwapableToken()
        }
    }

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
