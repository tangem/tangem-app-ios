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
import TangemMacro

struct TransactionSendAvailabilityProvider {
    private let hardwareLimitationsUtil: HardwareLimitationsUtil
    private let networkIconProvider: NetworkImageProvider

    init(
        hardwareLimitationsUtil: HardwareLimitationsUtil,
        networkIconProvider: NetworkImageProvider = NetworkImageProvider()
    ) {
        self.hardwareLimitationsUtil = hardwareLimitationsUtil
        self.networkIconProvider = networkIconProvider
    }

    func sendingRestrictions(walletModel: any WalletModel) -> SendingRestrictions? {
        switch hardwareLimitationsUtil.getSendLimitations(walletModel.tokenItem) {
        case .oldCard:
            return .oldCard
        case .longHashes, .oldDevice:
            return .cantSignLongTransactions
        case .none:
            break
        }

        if let restriction = walletModel.availableBalanceProvider.balanceType.sendingRestrictions {
            return restriction
        }

        // has pending tx
        if walletModel.hasAnyPendingTransactions, !walletModel.tokenItem.blockchain.isParallelTransactionAllowed {
            return .hasPendingTransaction(blockchain: walletModel.tokenItem.blockchain)
        }

        // no fee
        if !walletModel.hasFeeCurrency(),
           let configuration = makeNotEnoughFeeConfiguration(walletModel: walletModel) {
            return .zeroFeeCurrencyBalance(configuration: configuration)
        }

        return nil
    }

    private func makeNotEnoughFeeConfiguration(walletModel: any WalletModel) -> SendingRestrictions.NotEnoughFeeConfiguration? {
        do {
            let feeAmountTypeIconAsset = networkIconProvider.provide(by: walletModel.feeTokenItem.blockchain, filled: true)
            let feeWalletModelFinderResult = try WalletModelFinder.findWalletModel(tokenItem: walletModel.feeTokenItem)
            let availabilityProvider = TokenActionAvailabilityProvider(
                userWalletConfig: feeWalletModelFinderResult.userWalletModel.config,
                walletModel: feeWalletModelFinderResult.walletModel
            )

            return .init(
                amountCurrencySymbol: walletModel.tokenItem.currencySymbol,
                amountCurrencyBlockchainName: walletModel.tokenItem.blockchain.displayName,
                transactionAmountTypeName: walletModel.tokenItem.name,
                feeAmountTypeName: walletModel.feeTokenItem.name,
                feeAmountTypeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
                feeAmountTypeIconAsset: feeAmountTypeIconAsset,
                networkName: walletModel.tokenItem.networkName,
                currencyButtonTitle: walletModel.tokenItem.blockchain.feeDisplayName,
                isFeeCurrencyPurchaseAllowed: availabilityProvider.isBuyAvailable
            )
        } catch {
            AppLogger.error(error: "FeeWalletModel didn't found")
            return nil
        }
    }
}

// MARK: - SendingRestrictions

@CaseFlagable
enum SendingRestrictions: Hashable {
    case zeroWalletBalance
    case hasOnlyCachedBalance
    case cantSignLongTransactions
    case hasPendingWithdrawOrder
    case hasPendingTransaction(blockchain: Blockchain)
    case zeroFeeCurrencyBalance(configuration: NotEnoughFeeConfiguration)
    case blockchainUnreachable
    case blockchainLoading
    case oldCard

    struct NotEnoughFeeConfiguration: Hashable {
        let amountCurrencySymbol: String
        let amountCurrencyBlockchainName: String
        let transactionAmountTypeName: String
        let feeAmountTypeName: String
        let feeAmountTypeCurrencySymbol: String
        let feeAmountTypeIconAsset: ImageType
        let networkName: String
        let currencyButtonTitle: String?
        let isFeeCurrencyPurchaseAllowed: Bool
    }
}

// MARK: - TokenBalanceType + SendingRestrictions

extension TokenBalanceType {
    var sendingRestrictions: SendingRestrictions? {
        switch self {
        case .loading(.none):
            return .blockchainLoading
        case .empty, .failure(.none):
            return .blockchainUnreachable
        case .loading(.some), .failure(.some):
            return .hasOnlyCachedBalance
        case .loaded(let value) where value == .zero:
            return .zeroWalletBalance
        case .loaded:
            return nil
        }
    }
}
