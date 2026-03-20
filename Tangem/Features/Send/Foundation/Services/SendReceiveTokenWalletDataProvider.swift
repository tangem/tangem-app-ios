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

    private let sourceToken: SendSourceToken

    init(sourceToken: SendSourceToken) {
        self.sourceToken = sourceToken
    }
}

// MARK: - SendDestinationInteractorDependenciesProvider.ReceiveTokenWalletDataProvider

extension SendReceiveTokenWalletDataProvider: SendDestinationInteractorDependenciesProvider.ReceiveTokenWalletDataProvider {
    func sendWalletData(
        for tokenItem: TokenItem,
        inUserWalletWithInfo userWalletInfo: UserWalletInfo
    ) -> SendDestinationInteractorDependenciesProvider.SendingWalletData? {
        guard let walletModel = findSourceWalletModel() else {
            return nil
        }

        return makeSendWalletData(from: walletModel)
    }

    func swapWalletData(for tokenItem: TokenItem) -> SendDestinationInteractorDependenciesProvider.SendingWalletData? {
        guard let sourceWalletModel = findSourceWalletModel() else {
            return nil
        }

        return .init(
            walletAddresses: sourceWalletModel.addresses.map(\.value),
            suggestedWallets: SendSuggestedWalletsFactory().makeSuggestedWallets(forNetworkId: tokenItem.blockchain.networkId),
            destinationTransactionHistoryProvider: EmptySendDestinationTransactionHistoryProvider()
        )
    }
}

// MARK: - Private

private extension SendReceiveTokenWalletDataProvider {
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
                if FeatureProvider.isAvailable(.accounts) {
                    return AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
                } else {
                    return userWalletModel.walletModelsManager.walletModels
                }
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
