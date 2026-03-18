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
    func walletData(for tokenItem: TokenItem) -> SendDestinationInteractorDependenciesProvider.SendingWalletData? {
        let targetTokenItem: TokenItem

        switch sourceToken.tokenItem.token?.metadata.kind {
        case .nonFungible:
            // Non-fungible tokens always use wallet data of the main token of the network (i.e. `feeTokenItem`)
            // because there are no real wallet models for non-fungible tokens (`NFTSendWalletModelProxy` proxy is used instead)
            targetTokenItem = sourceToken.feeTokenItem
        case .fungible,
             .none:
            targetTokenItem = tokenItem
        }

        guard let walletModel = findWalletModel(for: targetTokenItem) else {
            return nil
        }

        return makeWalletData(from: walletModel)
    }
}

// MARK: - Private

private extension SendReceiveTokenWalletDataProvider {
    func findWalletModel(for tokenItem: TokenItem) -> (any WalletModel)? {
        userWalletRepository.models
            .flatMap { userWalletModel -> [any WalletModel] in
                AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)
            }
            .first { walletModel in
                walletModel.tokenItem == tokenItem
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
