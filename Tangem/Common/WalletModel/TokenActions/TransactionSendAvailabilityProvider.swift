//
//  TransactionSendAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TransactionSendAvailabilityProvider {
    private let isSendingSupportedByCard: Bool

    init(isSendingSupportedByCard: Bool) {
        self.isSendingSupportedByCard = isSendingSupportedByCard
    }

    func sendingRestrictions(walletModel: any WalletModel) -> SendingRestrictions? {
        guard isSendingSupportedByCard else {
            return .oldCard
        }

        if !AppUtils().canSignTransaction(for: walletModel.tokenItem) {
            return .cantSignLongTransactions
        }

        switch walletModel.availableBalanceProvider.balanceType {
        case .empty, .loading(.none), .failure(.none):
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
            return .zeroFeeCurrencyBalance(
                configuration: .init(
                    transactionAmountTypeName: walletModel.tokenItem.name,
                    feeAmountTypeName: walletModel.feeTokenItem.name,
                    feeAmountTypeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
                    feeAmountTypeIconName: walletModel.feeTokenItem.blockchain.iconNameFilled,
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
        case oldCard

        struct NotEnoughFeeConfiguration: Hashable {
            let transactionAmountTypeName: String
            let feeAmountTypeName: String
            let feeAmountTypeCurrencySymbol: String
            let feeAmountTypeIconName: String
            let networkName: String
            let currencyButtonTitle: String?
        }
    }
}
