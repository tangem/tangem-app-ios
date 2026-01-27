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
    @Injected(\.expressPendingTransactionsRepository) private var pendingTransactionRepository: ExpressPendingTransactionRepository

    /// [REDACTED_TODO_COMMENT]
    /// [REDACTED_INFO]
    private let userWalletId: UserWalletId?

    init(userWalletId: UserWalletId?) {
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
    func getExpressInteractorWallet(
        base: any ExpressInteractorDestinationWallet,
        searchType: SearchType
    ) async -> (any ExpressInteractorSourceWallet)? {
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

        // All tokens are available for swap - actual pair check happens on the exchange screen
        // Only filter out source token itself and custom tokens
        let searchableWalletModels = walletModels.filter { wallet in
            let isNotSource = wallet.walletModel.id != base.id
            let isNotCustom = !wallet.walletModel.isCustom

            return isNotSource && isNotCustom
        }

        ExpressLogger.info(self, "has searchableWalletModels: \(searchableWalletModels.map(\.walletModel.tokenItem.expressCurrency))")

        let lastSwappedWallet = searchableWalletModels.first(where: {
            isLastTransactionWith(walletModel: $0.walletModel, searchType: searchType)
        })

        if let lastSwappedWallet {
            ExpressLogger.info(self, "select lastSwappedWallet: \(lastSwappedWallet.walletModel.tokenItem.expressCurrency)")
            return lastSwappedWallet.asExpressInteractorWalletModelWrapper
        }

        let walletModelsWithPositiveBalance = searchableWalletModels.filter { ($0.fiatBalance ?? 0) > 0 }

        // If all wallets without balance
        if walletModelsWithPositiveBalance.isEmpty, let first = searchableWalletModels.first {
            ExpressLogger.info(self, "has a zero wallets with positive balance then selected: \(first.walletModel.tokenItem.expressCurrency)")
            return first.asExpressInteractorWalletModelWrapper
        }

        // If user has wallets with balance then sort they
        let sortedWallets = walletModelsWithPositiveBalance.sorted(by: {
            ($0.fiatBalance ?? 0) > ($1.fiatBalance ?? 0)
        })

        // Start searching destination with available providers
        if let maxBalanceWallet = sortedWallets.first {
            ExpressLogger.info(self, "selected maxBalanceWallet: \(maxBalanceWallet.walletModel.tokenItem.expressCurrency)")
            return maxBalanceWallet.asExpressInteractorWalletModelWrapper
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
    struct UserWalletInfoWalletModelPair {
        let userWalletInfo: UserWalletInfo
        let walletModel: any WalletModel

        var tokenItem: TokenItem {
            walletModel.tokenItem
        }

        var fiatBalance: Decimal? {
            walletModel.fiatAvailableBalanceProvider.balanceType.value
        }

        var asExpressInteractorWalletModelWrapper: ExpressInteractorWalletModelWrapper {
            ExpressInteractorWalletModelWrapper(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                expressOperationType: .swap
            )
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
