//
//  CommonSendDestinationWalletDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts

/// Provides wallet data for receive tokens in swap flows.
/// This class is responsible for finding the appropriate wallet model
/// for a given receive token and creating the corresponding wallet data.
final class CommonSendDestinationWalletDataProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let sourceToken: SendSourceToken

    init(sourceToken: SendSourceToken) {
        self.sourceToken = sourceToken
    }
}

// MARK: - SendDestinationInteractorDependenciesProvider.SendDestinationWalletDataProvider

extension CommonSendDestinationWalletDataProvider: SendDestinationInteractorDependenciesProvider.SendDestinationWalletDataProvider {
    func sendWalletData() -> SendDestinationInteractorDependenciesProvider.SendingWalletData? {
        guard let sourceWalletModel = findSourceWalletModel() else {
            return nil
        }

        return makeSendWalletData(from: sourceWalletModel)
    }

    /// Implementation details:
    ///
    /// In a swap, the source and receive tokens may be on different networks,
    /// and the receive token's destination wallet could be in any user wallet.
    /// Therefore:
    /// - `walletAddresses` comes from the **source** token's wallet model,
    ///   so the validator can detect "sending to yourself" against the source wallet
    /// - `suggestedWallets` aggregates wallets across **all** user wallets and accounts
    ///   for the receive token's network, giving the user the full choice of destinations
    /// - `destinationTransactionHistoryProvider` is an empty stub because we cannot
    ///   determine which user wallet the receive token belongs to.
    ///   The receive token may not even belong to any of the user's wallets
    func swapWalletData(for tokenItem: TokenItem) -> SendDestinationInteractorDependenciesProvider.SendingWalletData? {
        guard let sourceWalletModel = findSourceWalletModel() else {
            return nil
        }

        let walletAddresses = sourceWalletModel.addresses.map(\.value)

        return .init(
            walletAddresses: walletAddresses,
            suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(
                targetNetworkId: tokenItem.blockchain.networkId,
                ignoredAddresses: walletAddresses.toSet(),
                referenceTokenItem: tokenItem
            ),
            destinationTransactionHistoryProvider: EmptySendDestinationTransactionHistoryProvider()
        )
    }
}

// MARK: - Private

private extension CommonSendDestinationWalletDataProvider {
    func findSourceWalletModel() -> (any WalletModel)? {
        let targetTokenItem: TokenItem

        switch sourceToken.tokenItem.token?.metadata.kind {
        case .nonFungible:
            // Non-fungible tokens always use wallet data of the main token of the network (i.e. `feeTokenItem`)
            // because there are no real wallet models for non-fungible tokens (`NFTSendWalletModelProxy` proxy is used instead)
            targetTokenItem = sourceToken.feeTokenItem
        case .fungible,
             .none:
            targetTokenItem = sourceToken.tokenItem
        }

        return findWalletModel(for: targetTokenItem, inUserWalletWithInfo: sourceToken.userWalletInfo)
    }

    func findWalletModel(for tokenItem: TokenItem, inUserWalletWithInfo userWalletInfo: UserWalletInfo) -> (any WalletModel)? {
        userWalletRepository
            .models
            .filter { $0.userWalletId == userWalletInfo.id }
            .flatMap { userWalletModel -> [any WalletModel] in
                AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
            }
            .first { walletModel in
                walletModel.tokenItem == tokenItem
            }
    }

    func makeSendWalletData(from walletModel: any WalletModel) -> SendDestinationInteractorDependenciesProvider.SendingWalletData {
        let walletAddresses = walletModel.addresses.map(\.value)

        return .init(
            walletAddresses: walletAddresses,
            suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(walletModel: walletModel),
            destinationTransactionHistoryProvider: CommonSendDestinationTransactionHistoryProvider(
                transactionHistoryUpdater: walletModel,
                transactionHistoryMapper: TransactionHistoryMapper(
                    currencySymbol: walletModel.tokenItem.currencySymbol,
                    walletAddresses: walletAddresses,
                    showSign: false,
                    isToken: walletModel.tokenItem.isToken
                )
            )
        )
    }
}
