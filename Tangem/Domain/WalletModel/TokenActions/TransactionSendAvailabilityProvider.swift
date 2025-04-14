//
//  TransactionSendAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAssets

struct TransactionSendAvailabilityProvider {
    private let isSendingSupportedByCard: Bool
    private let networkIconProvider: NetworkImageProvider

    init(isSendingSupportedByCard: Bool, networkIconProvider: NetworkImageProvider = NetworkImageProvider()) {
        self.isSendingSupportedByCard = isSendingSupportedByCard
        self.networkIconProvider = networkIconProvider
    }

    func sendingRestrictions(walletModel: any WalletModel) -> SendingRestrictions? {
        guard isSendingSupportedByCard else {
            return .oldCard
        }

        if !AppUtils().canSend(walletModel.tokenItem) {
            return .cantSignLongTransactions
        }

        switch walletModel.availableBalanceProvider.balanceType {
        case .loading(.none):
            return .blockchainLoading
        case .empty, .failure(.none):
            return .blockchainUnreachable
        case .loading(.some), .failure(.some):
            return .hasOnlyCachedBalance
        case .loaded(let value) where value == .zero:
            return .zeroWalletBalance
        case .loaded:
            break
        }

        // has pending tx
        if walletModel.hasPendingTransactions, !walletModel.tokenItem.blockchain.isParallelTransactionAllowed {
            return .hasPendingTransaction(blockchain: walletModel.tokenItem.blockchain)
        }

        // no fee
        if !walletModel.hasFeeCurrency(amountType: walletModel.tokenItem.amountType) {
            let feeAmountTypeIconAsset = networkIconProvider.provide(by: walletModel.feeTokenItem.blockchain, filled: true)
            return .zeroFeeCurrencyBalance(
                configuration: .init(
                    transactionAmountTypeName: walletModel.tokenItem.name,
                    feeAmountTypeName: walletModel.feeTokenItem.name,
                    feeAmountTypeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
                    feeAmountTypeIconAsset: feeAmountTypeIconAsset,
                    networkName: walletModel.tokenItem.networkName,
                    currencyButtonTitle: walletModel.tokenItem.blockchain.feeDisplayName
                )
            )
        }

        return nil
    }
}

extension TransactionSendAvailabilityProvider {
    enum SendingRestrictions: Hashable {
        case zeroWalletBalance
        case hasOnlyCachedBalance
        case cantSignLongTransactions
        case hasPendingTransaction(blockchain: Blockchain)
        case zeroFeeCurrencyBalance(configuration: NotEnoughFeeConfiguration)
        case blockchainUnreachable
        case blockchainLoading
        case oldCard

        struct NotEnoughFeeConfiguration: Hashable {
            let transactionAmountTypeName: String
            let feeAmountTypeName: String
            let feeAmountTypeCurrencySymbol: String
            let feeAmountTypeIconAsset: ImageType
            let networkName: String
            let currencyButtonTitle: String?
        }
    }
}
