//
//  TransactionHistoryServiceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation

struct TransactionHistoryServiceProvider {
    let isSafe: Bool

    func makeTransactionHistoryService(tokenItem: TokenItem, walletManager: any WalletManager) -> TransactionHistoryService? {
        let factory = TransactionHistoryFactoryProvider().factory

        if tokenItem.blockchain.isDynamicAddressesSupported {
            return WalletTransactionHistoryService(
                tokenItem: tokenItem,
                walletProvider: walletManager,
                transactionHistoryProviderFactory: factory
            )
        }

        guard let provider = factory.makeProvider(for: tokenItem.blockchain, isToken: tokenItem.isToken, isSafe: isSafe) else {
            return nil
        }

        var addresses = walletManager.wallet.addresses.map { $0.value }

        if tokenItem.blockchain.isEvm {
            let converter = EthereumAddressConverterFactory().makeConverter(for: tokenItem.blockchainNetwork.blockchain)
            let convertedAddresses = addresses.map { (try? converter.convertToETHAddress($0)) ?? $0 }
            addresses = convertedAddresses.unique()
        }

        guard let address = addresses.singleElement else {
            #if INTERNAL || DEBUG
            preconditionFailure(
                "\(tokenItem.blockchain.displayName) has a transaction history provider and \(addresses.count) addresses, but doesn't support dynamic addresses"
            )
            #else
            return nil
            #endif
        }

        return CommonTransactionHistoryService(
            tokenItem: tokenItem,
            address: address,
            transactionHistoryProvider: provider
        )
    }
}
