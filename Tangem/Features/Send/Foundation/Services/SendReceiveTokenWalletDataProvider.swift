//
//  SendReceiveTokenWalletDataProvider.swift
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
final class SendReceiveTokenWalletDataProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    init() {}
}

// MARK: - SendDestinationInteractorDependenciesProvider.ReceiveTokenWalletDataProvider

extension SendReceiveTokenWalletDataProvider: SendDestinationInteractorDependenciesProvider.ReceiveTokenWalletDataProvider {
    func walletData(for tokenItem: TokenItem) -> SendDestinationInteractorDependenciesProvider.SendingWalletData? {
        guard let walletModel = findWalletModel(for: tokenItem) else {
            return nil
        }

        return makeWalletData(from: walletModel)
    }
}

// MARK: - Private

private extension SendReceiveTokenWalletDataProvider {
    func findWalletModel(for tokenItem: TokenItem) -> (any WalletModel)? {
        let targetNetworkId = tokenItem.blockchain.networkId

        return userWalletRepository.models
            .flatMap { userWalletModel -> [any WalletModel] in
                if FeatureProvider.isAvailable(.accounts) {
                    return AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
                } else {
                    return userWalletModel.walletModelsManager.walletModels
                }
            }
            .first { walletModel in
                walletModel.tokenItem.blockchain.networkId == targetNetworkId && walletModel.isMainToken
            }
    }

    func makeWalletData(from walletModel: any WalletModel) -> SendDestinationInteractorDependenciesProvider.SendingWalletData {
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
